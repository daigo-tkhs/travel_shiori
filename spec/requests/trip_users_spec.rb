# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "TripUsers", type: :request do
  let(:owner) { create(:user) }
  let(:member_to_delete) { create(:user) }
  let(:new_member) { create(:user, email: 'add_me@example.com') }
  let(:other_user) { create(:user) }
  let!(:trip) { create(:trip, owner: owner) }
  
  let!(:existing_trip_user) { create(:trip_user, trip: trip, user: member_to_delete, permission_level: 'viewer') }

  before { sign_in owner }

  # ============================================================================
  # POST /trips/:trip_id/trip_users (メンバー追加)
  # ============================================================================
  describe "POST /trips/:trip_id/trip_users" do
    let(:valid_params) { { trip_user: { email: new_member.email, role: 'editor' } } }

    context "正常系: オーナーによる追加" do
      it "TripUserレコードが新規作成されること" do
        expect {
          post trip_trip_users_path(trip), params: valid_params
        }.to change(TripUser, :count).by(1)
      end

      it "成功後に共有設定ページへリダイレクトされること" do
        post trip_trip_users_path(trip), params: valid_params
        expect(response).to redirect_to(sharing_trip_path(trip)) 
      end
    end

    context "異常系: 権限のないユーザーによる追加" do
      before { sign_in other_user }

      it "レコードは作成されず、アクセス拒否（リダイレクト）されること" do
        expect {
          post trip_trip_users_path(trip), params: valid_params
        }.not_to change(TripUser, :count)
        
        expect(response).to redirect_to(root_path) 
        expect(flash[:alert]).to be_present 
      end
    end
    
    context "異常系: 既にメンバーの場合 (メールアドレス渡し)" do
      let(:duplicate_params) { { trip_user: { email: member_to_delete.email, role: 'viewer' } } }

      it "レコードは作成されず、アラートと共にリダイレクトされること" do
        expect {
          post trip_trip_users_path(trip), params: duplicate_params
        }.not_to change(TripUser, :count)
        
        expect(response).to redirect_to(sharing_trip_path(trip))
        expect(flash[:alert]).to be_present 
      end
    end

    context "異常系: ユーザーが存在しない場合" do
      let(:non_existent_params) { { trip_user: { email: 'not_found@example.com', role: 'viewer' } } }

      it "レコードは作成されず、アラートと共にリダイレクトされること" do
        expect {
          post trip_trip_users_path(trip), params: non_existent_params
        }.not_to change(TripUser, :count)
        
        expect(response).to redirect_to(sharing_trip_path(trip))
        expect(flash[:alert]).to be_present
      end
    end
  end

  # ============================================================================
  # DELETE /trips/:trip_id/trip_users/:id (メンバー削除/離脱)
  # ============================================================================
  describe "DELETE /trips/:trip_id/trip_users/:id" do
    
    context "正常系: オーナーが他のメンバーを削除" do
      it "TripUserレコードが削除され、共有設定ページにリダイレクトされること" do
        expect {
          delete trip_trip_user_path(trip, existing_trip_user)
        }.to change(TripUser, :count).by(-1)
        
        expect(response).to redirect_to(sharing_trip_path(trip))
      end
    end
    
    context "正常系: メンバー自身が旅程から離脱" do
      before { sign_in member_to_delete }

      it "TripUserレコードが削除され、旅程一覧ページにリダイレクトされること" do
        expect {
          delete trip_trip_user_path(trip, existing_trip_user)
        }.to change(TripUser, :count).by(-1)
        
        expect(response).to redirect_to(trips_path)
      end
    end

    context "異常系: 権限のないユーザー（閲覧者など）による削除" do
      before { sign_in other_user }

      it "レコードは削除されず、アクセス拒否（リダイレクト）されること" do
        expect {
          delete trip_trip_user_path(trip, existing_trip_user)
        }.not_to change(TripUser, :count)
        
        expect(response).to redirect_to(root_path) 
        expect(flash[:alert]).to be_present
      end
    end
  end
end