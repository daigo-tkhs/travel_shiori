class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_trip, only: [:index, :create, :update, :destroy]

  def index
    @messages = @trip.messages.order(created_at: :asc)
    @message = Message.new
  end

  def create
    @message = @trip.messages.build(message_params)
    @message.user = current_user

    if @message.save
      begin
        # --- Gemini API連携設定 ---
        
        # AIへの指示書（システムプロンプト）
        # ここで「スポット提案の時はJSONを返せ」と指示します
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

        # 過去の会話履歴を含めて送信（文脈理解のため）
        # ※今回は簡易化のため、直前のやり取りとシステムプロンプトのみ送ります
        result = client.generate_content({
          contents: { role: 'user', parts: { text: @message.prompt } },
          system_instruction: { parts: { text: system_instruction } }
        })

        Rails.logger.info "Gemini API Result: #{result.inspect}"

        # レスポンスの取得
        raw_response = result.is_a?(Array) ? result.first : result
        
        if raw_response && raw_response['candidates'].present?
           candidates = raw_response['candidates']
           ai_response = candidates[0].dig('content', 'parts', 0, 'text')
           
           if ai_response.present?
             # AIの返答をそのまま保存（JSONかテキストかはビューで判断）
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
        Rails.logger.error e.backtrace.join("\n")
        redirect_to trip_messages_path(@trip), alert: "AIとの通信に失敗しました: #{e.message}"
      end
    else
      redirect_to trip_messages_path(@trip), alert: 'メッセージを入力してください。'
    end
  end

  private

  def set_trip
    @trip = Trip.shared_with_user(current_user).find(params[:trip_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "指定された旅程が見つからないか、アクセス権がありません。"
  end

  def message_params
    params.require(:message).permit(:prompt)
  end
end