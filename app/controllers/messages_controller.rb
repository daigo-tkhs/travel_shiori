# frozen_string_literal: true

class MessagesController < ApplicationController
  
  before_action :authenticate_user!
  before_action :set_trip
  before_action :set_message, only: %i[edit update destroy]

  def index
    # 権限チェック: TripPolicy#show? をチェック (閲覧権限)
    authorize @trip
    
    @hide_header = true
    @messages = @trip.messages.order(created_at: :asc)
    @message = Message.new
  end

  def edit
    # 権限チェック: MessagePolicy#edit? をチェック
    authorize @message
  end

  def create
    @message = @trip.messages.build(message_params)
    @message.user = current_user
    
    # 権限チェック: MessagePolicy#create? をチェック (編集権限)
    authorize @message

    if @message.save
      generate_ai_response(@message)
    else
      redirect_to trip_messages_path(@trip), alert: t('messages.user_message.create_failure')
    end
  end

  def update
    # 権限チェック: MessagePolicy#update? をチェック
    authorize @message

    @trip.messages.where('created_at > ?', @message.created_at).destroy_all

    if @message.update(message_params)
      generate_ai_response(@message)
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    # 権限チェック: MessagePolicy#destroy? をチェック (編集権限または作成者自身)
    authorize @message
    
    @message.destroy
    respond_to do |format|
      format.html do
        redirect_to trip_messages_path(@trip),
                     notice: t('messages.user_message.delete_success'),
                     status: :see_other
      end
      format.turbo_stream
    end
  end

  private

  def generate_ai_response(message_record)
    system_instruction, contents = build_request_content(message_record)

    raw_response = handle_ai_api_request(system_instruction, contents)

    handle_ai_response(message_record, raw_response)
  rescue StandardError => e
    Rails.logger.error "Gemini API Error: #{e.message}"
    redirect_to trip_messages_path(@trip), alert: t('messages.ai.communication_error', error: e.message)
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

  def build_request_content(message_record)
    system_instruction = helpers.build_system_instruction_for_ai

    # 会話履歴の構築ロジックを分離
    contents = build_conversation_contents(message_record)
    [system_instruction, contents]
  end

  # 会話履歴の構築ロジックを分離
  def build_conversation_contents(message_record)
    past_messages = @trip.messages.order(created_at: :asc)

    contents = []
    past_messages.each do |msg|
      # 自身より古いメッセージだけを履歴に含める
      if msg.created_at < message_record.created_at
        contents << { role: 'user', parts: [{ text: msg.prompt }] }
        contents << { role: 'model', parts: [{ text: msg.response }] } if msg.response.present?
      end
    end

    contents << { role: 'user', parts: [{ text: message_record.prompt }] }

    contents
  end

  def handle_ai_response(message_record, raw_response)
    if raw_response && raw_response['candidates'].present?
      candidates = raw_response['candidates']
      ai_response = candidates[0].dig('content', 'parts', 0, 'text')

      if ai_response.present?
        message_record.update!(response: ai_response)
        redirect_to trip_messages_path(@trip)
      else
        redirect_to trip_messages_path(@trip), alert: t('messages.ai.response_text_not_found')
      end
    else
      redirect_to trip_messages_path(@trip), alert: t('messages.ai.no_valid_response')
    end
  end

  def set_trip
    @trip = Trip.find(params[:trip_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: t('messages.trip.not_found')
  end

  def set_message
    # NOTE: 権限のないユーザーが他人のメッセージを編集/削除できないよう、Punditでチェック
    @message = @trip.messages.find(params[:id]) 
  rescue ActiveRecord::RecordNotFound
    redirect_to trip_messages_path(@trip), alert: t('messages.user_message.not_found')
  end

  def message_params
    params.require(:message).permit(:prompt)
  end
  
end