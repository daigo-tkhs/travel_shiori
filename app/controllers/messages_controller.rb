# frozen_string_literal: true

class MessagesController < ApplicationController
  
  before_action :authenticate_user!
  before_action :set_trip
  before_action :set_message, only: %i[edit update destroy]

  def index
    authorize @trip, :ai_chat?
    
    @hide_header = true
    @messages = @trip.messages.order(created_at: :asc)
    @message = Message.new
    
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def edit
    authorize @message
    render 'edit'
  end

  def create
    @message = @trip.messages.build(message_params)
    @message.user = current_user
    
    authorize @message

    if @message.save
      generate_ai_response(@message)
    else
      redirect_to trip_messages_path(@trip), alert: t('messages.user_message.create_failure')
    end
  end

  def update
    authorize @message

    @trip.messages.where('created_at > ?', @message.created_at).destroy_all

    if @message.update(message_params)
      generate_ai_response(@message)
    else
      # エラー時も Turbo Stream で編集フォームを再表示
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @message
    
    @message.destroy
    respond_to do |format|
      # Flashメッセージを flash.now で設定
      flash.now[:notice] = t('messages.user_message.delete_success') 
      
      # HTMLリクエストの場合はリダイレクトを維持
      format.html { redirect_to trip_messages_path(@trip), status: :see_other } 
      
      # Turbo Streamリクエストの場合は、専用ビューを使用
      format.turbo_stream
    end
  end

  def generate_ai_response(message_record)
    system_instruction, contents = build_request_content(message_record)

    raw_response = handle_ai_api_request(system_instruction, contents)

    handle_ai_response_and_redirect(message_record, raw_response)
  rescue StandardError => e
    Rails.logger.error "Gemini API Error: #{e.message}"
    redirect_to trip_messages_path(@trip), alert: t('messages.ai.communication_error', error: e.message)
  end

  private

  def handle_ai_response_and_redirect(message_record, raw_response)
    if raw_response && raw_response['candidates'].present?
      candidates = raw_response['candidates']
      ai_response = candidates[0].dig('content', 'parts', 0, 'text')

      if ai_response.present?
        message_record.update!(response: ai_response)
        
        # @messages を再定義（Turbo Stream レンダリングに必要）
        @messages = @trip.messages.order(created_at: :asc)
        @hide_header = true

        respond_to do |format|
          # ★修正箇所: 'messages/index' のテンプレートを使ってレンダリング
          # Railsは自動的に messages/index.turbo_stream.erb を選択します。
          format.turbo_stream { render 'messages/index', status: :ok }
          format.html { redirect_to trip_messages_path(@trip) }
        end
      else
        redirect_to trip_messages_path(@trip), alert: t('messages.ai.response_text_not_found')
      end
    else
      redirect_to trip_messages_path(@trip), alert: t('messages.ai.no_valid_response')
    end
  end
  
  def build_request_content(message_record)
    system_instruction, contents = helpers.build_system_instruction_for_ai
    contents = build_conversation_contents(message_record)
    [system_instruction, contents]
  end

  def build_conversation_contents(message_record)
    past_messages = @trip.messages.order(created_at: :asc)
    contents = []
    past_messages.each do |msg|
      if msg.created_at < message_record.created_at
        contents << { role: 'user', parts: [{ text: msg.prompt }] }
        contents << { role: 'model', parts: [{ text: msg.response }] } if msg.response.present?
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

  def message_params
    params.require(:message).permit(:prompt)
  end
  
end