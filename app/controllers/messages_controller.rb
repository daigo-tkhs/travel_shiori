class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_trip
  before_action :set_message, only: [:edit, :update, :destroy]

  def index
    @messages = @trip.messages.order(created_at: :asc)
    @message = Message.new
  end

  def create
    @message = @trip.messages.build(message_params)
    @message.user = current_user

    if @message.save
      # --- AI連携ロジック (既存のまま) ---
      begin
        system_instruction = <<~INSTRUCTION
          あなたは旅行プランニングのアシスタントです。
          ユーザーの要望に合わせて、観光スポットやレストランを提案してください。
          
          【重要】
          具体的なスポットを提案する場合は、必ず以下の**JSON形式のみ**で返答してください。余計な文章は不要です。
          提案するスポットがない場合（挨拶や質問への回答など）は、普通のテキストで返答してください。
          
          # スポット提案時のJSONフォーマット例:
          {
            "is_suggestion": true,
            "spots": [
              {
                "name": "東京タワー",
                "description": "東京のシンボル。メインデッキからは東京の景色を一望できます。",
                "estimated_cost": 1200,
                "duration": 60
              }
            ],
            "message": "東京タワーはいかがでしょうか？定番ですが外せません！"
          }
        INSTRUCTION

        client = Gemini.new(
          credentials: {
            service: 'generative-language-api',
            version: 'v1beta',
            api_key: Rails.application.credentials.gemini[:api_key]
          },
          options: { model: 'gemini-2.0-flash', server_sent_events: false }
        )

        result = client.generate_content({
          contents: { role: 'user', parts: { text: @message.prompt } },
          system_instruction: { parts: { text: system_instruction } }
        })

        raw_response = result.is_a?(Array) ? result.first : result
        
        if raw_response && raw_response['candidates'].present?
           candidates = raw_response['candidates']
           ai_response = candidates[0].dig('content', 'parts', 0, 'text')
           
           if ai_response.present?
             @message.update!(response: ai_response)
             redirect_to trip_messages_path(@trip)
           else
             redirect_to trip_messages_path(@trip), alert: 'AIからの応答テキストが見つかりませんでした。'
           end
        else
           redirect_to trip_messages_path(@trip), alert: 'AIからの有効な応答がありませんでした。'
        end

      rescue => e
        Rails.logger.error "Gemini API Error: #{e.message}"
        redirect_to trip_messages_path(@trip), alert: "AIとの通信に失敗しました: #{e.message}"
      end
      # -----------------------------------
    else
      redirect_to trip_messages_path(@trip), alert: 'メッセージを入力してください。'
    end
  end

  def edit
    # ビュー側でフォームを表示
  end

  def update
    if @message.update(message_params)
      redirect_to trip_messages_path(@trip), notice: 'メッセージを更新しました。'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @message.destroy
    redirect_to trip_messages_path(@trip), notice: 'メッセージを削除しました。', status: :see_other
  end

  private

  def set_trip
    @trip = Trip.shared_with_user(current_user).find(params[:trip_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "指定された旅程が見つからないか、アクセス権がありません。"
  end

  # 自分のメッセージのみ取得（他人のメッセージは編集不可）
  def set_message
    @message = @trip.messages.where(user_id: current_user.id).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to trip_messages_path(@trip), alert: "権限がないか、メッセージが見つかりません。"
  end

  def message_params
    params.require(:message).permit(:prompt)
  end
end