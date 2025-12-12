# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Messages", type: :request do
  let(:owner) { create(:user) }
  let(:viewer) { create(:user) }
  let!(:trip) { create(:trip, owner: owner) }
  
  # TripUserの権限を設定
  let!(:trip_user_viewer) { create(:trip_user, trip: trip, user: viewer, permission_level: 'viewer') }
  
  # 既存のメッセージ
  let!(:message) { create(:message, trip: trip, user: owner) } 
  
  # 新しいメッセージの有効なパラメータ
  let(:valid_message_params) { { message: { prompt: "次の日の天気は？" } } }

  # 共通処理: デフォルトではオーナーでログイン
  before { sign_in owner }

  # ============================================================================
  # POST /trips/:trip_id/messages (メッセージ作成)
  # ============================================================================
  describe "POST /trips/:trip_id/messages" do
    context "正常系: オーナーによる作成" do
      it "新しいメッセージが作成されること" do
        expect {
          post trip_messages_path(trip), params: valid_message_params
        }.to change(Message, :count).by(1)
      end

      it "作成後にリダイレクトされること" do
        post trip_messages_path(trip), params: valid_message_params
        expect(response).to redirect_to(trip_messages_path(trip)) # 会話履歴ページにリダイレクトと想定
      end
    end

    context "異常系: 閲覧者による作成" do
      before { sign_in viewer }

      it "メッセージは作成されないこと" do
        expect {
          post trip_messages_path(trip), params: valid_message_params
        }.not_to change(Message, :count)
      end
    end
  end

  # ============================================================================
  # DELETE /trips/:trip_id/messages/:id (削除)
  # ============================================================================
  describe "DELETE /trips/:trip_id/messages/:id" do
    context "正常系: オーナーによる削除" do
      it "メッセージが削除されること" do
        expect {
          delete trip_message_path(trip, message)
        }.to change(Message, :count).by(-1)
      end
    end

    context "異常系: 閲覧者による削除" do
      before { sign_in viewer }

      it "メッセージは削除されないこと" do
        expect {
          delete trip_message_path(trip, message)
        }.not_to change(Message, :count)
      end
    end
  end
end