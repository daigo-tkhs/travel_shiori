# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Checklists", type: :request do
  let(:owner) { create(:user) }
  let(:viewer) { create(:user) }
  let!(:trip) { create(:trip, owner: owner) }
  
  # 既存のチェックリストアイテム
  let!(:item) { create(:checklist_item, trip: trip, name: "歯ブラシ") }

  # 共通処理: デフォルトではオーナーでログイン
  before { sign_in owner }

  # ============================================================================
  # POST /trips/:trip_id/checklists (作成)
  # ============================================================================
  describe "POST /trips/:trip_id/checklists" do
    let(:valid_params) { { checklist_item: { name: "タオル" } } }

    context "正常系: オーナーによる作成" do
      it "新しいチェックリストアイテムが作成されること" do
        expect {
          post trip_checklists_path(trip), params: valid_params
        }.to change(ChecklistItem, :count).by(1)
      end
    end
  end

  # ============================================================================
  # PATCH /trips/:trip_id/checklists/:id (更新 - チェック状態の変更を想定)
  # ============================================================================
  describe "PATCH /trips/:trip_id/checklists/:id" do
    let(:update_params) { { checklist_item: { is_checked: true } } }

    context "正常系: オーナーによる更新" do
      it "チェック状態が更新されること" do
        patch trip_checklist_path(trip, item), params: update_params
        item.reload
        expect(item.is_checked).to be true
      end
    end

    context "異常系: 閲覧者による更新" do
      before { sign_in viewer }
      
      it "チェック状態が更新されないこと" do
        patch trip_checklist_path(trip, item), params: update_params
        item.reload
        expect(item.is_checked).to be false
      end
    end
  end

  # ============================================================================
  # DELETE /trips/:trip_id/checklists/:id (削除)
  # ============================================================================
  describe "DELETE /trips/:trip_id/checklists/:id" do
    context "正常系: オーナーによる削除" do
      it "チェックリストアイテムが削除されること" do
        expect {
          delete trip_checklist_path(trip, item)
        }.to change(ChecklistItem, :count).by(-1)
      end
    end

    context "異常系: 閲覧者による削除" do
      before { sign_in viewer }

      it "アイテムは削除されないこと" do
        expect {
          delete trip_checklist_path(trip, item)
        }.not_to change(ChecklistItem, :count)
      end
    end
  end
end