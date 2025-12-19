# frozen_string_literal: true

class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_trip
  # 修正：Punditの代わりにモデルのメソッドで権限チェック
  before_action :ensure_viewable!, only: %i[index show]
  before_action :set_message, only: %i[edit update destroy]
  # 編集・削除はメッセージの所有者本人のみ
  before_action :ensure_message_owner!, only: %i[edit update destroy]

  def index
    @hide_header = true
    @messages = @trip.messages.includes(:user).order(created_at: :asc)
    @message = Message.new
    
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    redirect_to trip_messages_path(@trip)
  end

  def edit
    render 'edit'
  end

  def create
    @message = @trip.messages.build(message_params)
    @message.user = current_user
    
    # バリデーション前に簡易的な権限チェック（閲覧者なら投稿OKとする場合）
    unless @trip.viewable_by?(current_user)
      return redirect_to root_path, alert: "権限がありません。"
    end

    if @message.save
      @ai_message = generate_ai_response(@message)

      respond_to do |format|
        format.html { redirect_to trip_messages_path(@trip), notice: t('messages.user_message.create_success') }
        format.turbo_stream
      end
    else
      redirect_to trip_messages_path(@trip), alert: t('messages.user_message.create_failure')
    end
  end

  def update
    # 過去の関連メッセージ（AI応答など）を削除するロジックは維持
    obsolete_messages = @trip.messages.where('id > ?', @message.id)
    @deleted_message_ids = obsolete_messages.pluck(:id)
    obsolete_messages.destroy_all

    if @message.update(message_params)
      @ai_message = generate_ai_response(@message)

      respond_to do |format|
        format.html { redirect_to trip_messages_path(@trip), notice: t('messages.user_message.update_success') }
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    obsolete_messages = @trip.messages.where('id > ?', @message.id)
    @deleted_message_ids = obsolete_messages.pluck(:id)
    obsolete_messages.destroy_all
    
    @message.destroy

    respond_to do |format|
      flash.now[:notice] = t('messages.user_message.delete_success') 
      format.html { redirect_to trip_messages_path(@trip), status: :see_other } 
      format.turbo_stream
    end
  end

  # --- AI生成ロジック ---
  def generate_ai_response(message_record)
    system_instruction, contents = build_request_content(message_record)
    raw_response = handle_ai_api_request(system_instruction, contents)
    handle_ai_response(raw_response)
  rescue StandardError => e
    Rails.logger.error "Gemini API Error: #{e.message}"
    @trip.messages.create!(response: t('messages.ai.communication_error', error: e.message), user_id: nil)
  end

  private

  def handle_ai_response(raw_response)
    ai_response = nil
    if raw_response && raw_response['candidates'].present?
      ai_response = raw_response['candidates'][0].dig('content', 'parts', 0, 'text')
    end

    if ai_response.present?
      cleaned_response = ai_response.gsub(/```json\s*\{.*?\}\s*```/m, '').strip
      response_text = cleaned_response.present? ? cleaned_response : t('messages.ai.no_valid_response')
    else
      response_text = t('messages.ai.no_valid_response')
    end

    @trip.messages.create!(response: response_text, user_id: nil) 
  end
  
  def build_request_content(message_record)
    system_instruction, = helpers.build_system_instruction_for_ai
    contents = build_conversation_contents(message_record)
    [system_instruction, contents]
  end

  def build_conversation_contents(message_record)
    past_messages = @trip.messages.order(created_at: :asc)
    contents = []
    
    past_messages.each do |msg|
      role_type = msg.user_id.present? ? 'user' : 'model' 
      if msg.created_at < message_record.created_at
        text_content = msg.prompt.presence || msg.response.presence
        if text_content
          contents << { role: role_type, parts: [{ text: text_content }] }
        end
      end
    end
    contents << { role: 'user', parts: [{ text: message_record.prompt }] }
    contents
  end
  
  def handle_ai_api_request(system_instruction, contents)
    client = Gemini.new(
      credentials: {
        service: 'generative-language-api',
        version: 'v1beta',
        api_key: Rails.application.credentials.gemini[:api_key]
      },
      options: { model: 'gemini-2.0-flash', server_sent_events: false }
    )

    result = client.generate_content({
                                       contents: contents,
                                       system_instruction: { parts: { text: system_instruction } }
                                     })
    result.is_a?(Array) ? result.first : result
  end

  # --- ヘルパーメソッド ---

  def set_trip
    @trip = Trip.find(params[:trip_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: t('messages.trip.not_found')
  end

  def set_message
    @message = @trip.messages.find(params[:id]) 
  rescue ActiveRecord::RecordNotFound
    redirect_to trip_messages_path(@trip), alert: t('messages.user_message.not_found')
  end

  # 権限チェック：閲覧可能か
  def ensure_viewable!
    unless @trip.viewable_by?(current_user)
      redirect_to root_path, alert: "アクセス権限がありません。"
    end
  end

  # 権限チェック：メッセージの編集・削除は本人のみ
  def ensure_message_owner!
    unless @message.user_id == current_user.id
      redirect_to trip_messages_path(@trip), alert: "操作権限がありません。"
    end
  end

  def message_params
    params.require(:message).permit(:prompt)
  end
end