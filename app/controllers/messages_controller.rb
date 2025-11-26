# app/controllers/messages_controller.rb

class MessagesController < ApplicationController
  before_action :authenticate_user!
  # indexアクションを含め、すべてのアクションの前に旅程を取得する設定を確実に適用
  before_action :set_trip, only: [:index, :create, :update, :destroy]

  def index
    # この旅程に関連するメッセージを全て取得（作成順）
    @messages = @trip.messages.order(created_at: :asc)
    # 新規投稿用の空のインスタンス
    @message = Message.new
  end

  def create
    @message = @trip.messages.build(message_params)
    @message.user = current_user

    if @message.save
      begin
        # --- Gemini API連携 ---
        client = Gemini.new(
          credentials: {
            service: 'generative-language-api',
            api_key: Rails.application.credentials.gemini[:api_key]
          },
          options: { model: 'gemini-pro', server_sent_events: false }
        )

        # ユーザーの入力をAIに送信
        result = client.generate_content({
          contents: { role: 'user', parts: { text: @message.prompt } }
        })

        # レスポンスの取得と保存
        if result && result.any?
           candidates = result[0].fetch('candidates', [])
           if candidates.any?
             ai_response = candidates[0]['content']['parts'][0]['text']
             @message.update!(response: ai_response)
             redirect_to trip_messages_path(@trip), notice: 'AIからの返信が届きました！'
           else
             redirect_to trip_messages_path(@trip), alert: 'AIからの応答が空でした。'
           end
        else
           redirect_to trip_messages_path(@trip), alert: 'AIからの応答がありませんでした。'
        end

      rescue => e
        Rails.logger.error "Gemini API Error: #{e.message}"
        redirect_to trip_messages_path(@trip), alert: "AIとの通信に失敗しました: #{e.message}"
      end
    else
      redirect_to trip_messages_path(@trip), alert: 'メッセージを入力してください。'
    end
  end

  private

  def set_trip
    # URLの :trip_id パラメータから旅程を取得
    @trip = Trip.shared_with_user(current_user).find(params[:trip_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "指定された旅程が見つからないか、アクセス権がありません。"
  end

  def message_params
    params.require(:message).permit(:prompt)
  end
end