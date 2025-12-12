# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Favorites", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  
  # 他のユーザーが所有する旅程
  let!(:trip) { create(:trip, owner: other_user) } 
  
  # ▼▼▼ 修正: userがtripを閲覧できるように、TripUserを追加 ▼▼▼
  # 閲覧権限（viewer）で十分
  let!(:trip_user) { create(:trip_user, trip: trip, user: user, permission_level: 'viewer') } 
  # ▲▲▲ 修正終わり ▲▲▲

  # 共通処理: ログインしておく
  before { sign_in user }

  # ============================================================================
  # POST /trips/:trip_id/favorite (お気に入り登録)
  # ============================================================================
  describe "POST /trips/:trip_id/favorite" do
    context "正常系" do
      it "お気に入りレコードが新規作成されること" do
        expect {
          post trip_favorite_path(trip)
        }.to change(Favorite, :count).by(1)
      end

      it "既に登録済みの場合、レコードは増えないこと" do
        # 既に登録されているFavoriteは、このuserとtripの組み合わせである必要がある
        create(:favorite, user: user, trip: trip)
        
        expect {
          post trip_favorite_path(trip)
        }.not_to change(Favorite, :count)
      end
      
      it "登録後、詳細ページにリダイレクトされること" do
        post trip_favorite_path(trip)
        expect(response).to redirect_to(trip_path(trip))
      end
    end

    context "異常系: 未ログインの場合" do
      before { sign_out user } # ログアウト

      it "レコードは作成されず、ログインページにリダイレクトされること" do
        expect {
          post trip_favorite_path(trip)
        }.not_to change(Favorite, :count)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # ============================================================================
  # DELETE /trips/:trip_id/favorite (お気に入り解除)
  # ============================================================================
  describe "DELETE /trips/:trip_id/favorite" do
    # 事前にお気に入りを作成しておく
    # NOTE: let! で作成することで、テスト開始時にレコードが存在する
    let!(:favorite) { create(:favorite, user: user, trip: trip) }

    context "正常系" do
      it "お気に入りレコードが削除されること" do
        expect {
          delete trip_favorite_path(trip)
        }.to change(Favorite, :count).by(-1)
      end
      
      it "削除後、詳細ページにリダイレクトされること" do
        delete trip_favorite_path(trip)
        expect(response).to redirect_to(trip_path(trip))
      end
    end

    context "異常系: 未ログインの場合" do
      before { sign_out user } # ログアウト

      it "レコードは削除されず、ログインページにリダイレクトされること" do
        expect {
          delete trip_favorite_path(trip)
        }.not_to change(Favorite, :count)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end