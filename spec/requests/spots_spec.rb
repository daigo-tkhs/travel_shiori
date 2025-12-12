# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Spots", type: :request do
  # テストデータ
  let(:owner) { create(:user) }
  let(:other_user) { create(:user) }
  let(:editor) { create(:user) }
  let!(:trip) { create(:trip, owner: owner) }
  # 旅程の編集者を作成
  let!(:trip_user_editor) { create(:trip_user, trip: trip, user: editor, permission_level: 'editor') }
  # テスト対象のスポット
  let!(:spot) { create(:spot, trip: trip, name: "既存スポット") }

  # 新しいスポット用の有効なパラメータ
  let(:valid_spot_params) { { spot: attributes_for(:spot, name: "新しいスポット") } }
  # 無効なパラメータ (名前を空にする)
  let(:invalid_spot_params) { { spot: attributes_for(:spot, name: "") } }

  # 共通処理: 基本的に所有者(owner)でログインしておく
  before do
    sign_in owner
  end

  # ============================================================================
  # POST /trips/:trip_id/spots (新規作成)
  # ============================================================================
  describe "POST /trips/:trip_id/spots" do
    # ------------------------------------------------------------------
    # 正常系: 権限があるユーザー
    # ------------------------------------------------------------------
    context "正常系: 所有者による作成" do
      it "有効なパラメータの場合、スポットが作成されること" do
        expect {
          post trip_spots_path(trip), params: valid_spot_params
        }.to change(Spot, :count).by(1)
      end

      it "作成後に旅程詳細ページにリダイレクトされること" do
        post trip_spots_path(trip), params: valid_spot_params
        expect(response).to redirect_to(trip_path(trip))
      end
    end
    
    context "正常系: 編集者による作成" do
      before { sign_in editor }

      it "有効なパラメータの場合、スポットが作成されること" do
        expect {
          post trip_spots_path(trip), params: valid_spot_params
        }.to change(Spot, :count).by(1)
      end
    end
    
    # ------------------------------------------------------------------
    # 異常系: 権限なし/バリデーションエラー
    # ------------------------------------------------------------------
    context "異常系: 権限のないユーザー" do
      before { sign_in other_user }

      it "スポットは作成されないこと" do
        expect {
          post trip_spots_path(trip), params: valid_spot_params
        }.not_to change(Spot, :count)
      end

      it "アクセス拒否（リダイレクト）されること" do
        post trip_spots_path(trip), params: valid_spot_params
        expect(response).to have_http_status(:redirect)
      end
    end

    context "異常系: バリデーションエラー（所有者）" do
      it "無効なパラメータの場合、スポットは作成されないこと" do
        expect {
          post trip_spots_path(trip), params: invalid_spot_params
        }.not_to change(Spot, :count)
      end
      
      it "エラー等でステータス 422 (Unprocessable Entity) が返されること" do
        post trip_spots_path(trip), params: invalid_spot_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  # ============================================================================
  # PATCH /trips/:trip_id/spots/:id (更新)
  # ============================================================================
  describe "PATCH /spots/:id" do
    let(:new_name) { "更新されたスポット名" }
    
    # ------------------------------------------------------------------
    # 正常系
    # ------------------------------------------------------------------
    context "正常系: 所有者による更新" do
      it "スポットが更新されること" do
        patch trip_spot_path(trip, spot), params: { spot: { name: new_name } }
        spot.reload
        expect(spot.name).to eq new_name
      end
    end

    # ------------------------------------------------------------------
    # 異常系: 権限なし
    # ------------------------------------------------------------------
    context "異常系: 権限のないユーザー" do
      before { sign_in other_user }

      it "スポットは更新されないこと" do
        patch trip_spot_path(trip, spot), params: { spot: { name: new_name } }
        spot.reload
        expect(spot.name).not_to eq new_name
      end
    end
  end

  # ============================================================================
  # DELETE /trips/:trip_id/spots/:id (削除)
  # ============================================================================
  describe "DELETE /spots/:id" do
    # ------------------------------------------------------------------
    # 正常系
    # ------------------------------------------------------------------
    context "正常系: 所有者による削除" do
      it "スポットが削除されること" do
        expect {
          delete trip_spot_path(trip, spot)
        }.to change(Spot, :count).by(-1)
      end
    end

    # ------------------------------------------------------------------
    # 異常系: 権限なし
    # ------------------------------------------------------------------
    context "異常系: 権限のないユーザー" do
      before { sign_in other_user }

      it "スポットは削除されないこと" do
        expect {
          delete trip_spot_path(trip, spot)
        }.not_to change(Spot, :count)
      end
    end
  end
end