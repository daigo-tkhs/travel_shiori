# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Trip, type: :model do
  # 共通のテストデータ
  let(:user) { create(:user) }
  let(:trip) { build(:trip, owner: user) }

  describe 'バリデーション' do
    context '正常系' do
      it 'すべての値が正しく設定されていれば有効であること' do
        expect(trip).to be_valid
      end
    end

    context '必須項目の確認' do
      it 'タイトルが空の場合は無効であること' do
        trip.title = ''
        expect(trip).to be_invalid
        expect(trip.errors[:title]).to include("を入力してください")
      end

      it '開始日が空の場合は無効であること' do
        trip.start_date = nil
        expect(trip).to be_invalid
        expect(trip.errors[:start_date]).to include("を入力してください")
      end

      it '終了日が空の場合は無効であること' do
        trip.end_date = nil
        expect(trip).to be_invalid
        expect(trip.errors[:end_date]).to include("を入力してください")
      end
    end

    context '日付の整合性チェック' do
      it '終了日が開始日より前の場合は無効であること' do
        trip.start_date = Date.today
        trip.end_date = Date.today - 1.day
        expect(trip).to be_invalid
        # ▼修正: エラーメッセージを実装に合わせて変更
        expect(trip.errors[:end_date]).to include("は開始日より後の日付を選択してください")
      end

      it '開始日と終了日が同じ日は有効であること（日帰り旅行）' do
        trip.start_date = Date.today
        trip.end_date = Date.today
        expect(trip).to be_valid
      end
    end

    context '数値のチェック' do
      it '予算が負の数の場合は無効であること' do
        trip.total_budget = -1000
        expect(trip).to be_invalid
      end
    end
  end

  describe '関連付けの削除依存性 (dependent: :destroy)' do
    it '旅程を削除すると、紐付いているスポットも削除されること' do
      trip.save!
      # ▼修正: address カラムを除外 (Spotモデルに存在しないため)
      trip.spots.create!(name: 'テストスポット', position: 1)
      
      expect { trip.destroy }.to change(Spot, :count).by(-1)
    end

    it '旅程を削除すると、紐付いている招待状も削除されること' do
      trip.save!
      # ▼修正: sender (招待者) を指定して作成
      trip.trip_invitations.create!(email: 'test@example.com', role: 'viewer', token: 'token123', sender: user)
      
      expect { trip.destroy }.to change(TripInvitation, :count).by(-1)
    end
  end

  describe 'スコープ: .shared_with_user' do
    let(:owner) { create(:user) }
    let(:member) { create(:user) }
    let(:other_user) { create(:user) }
    
    let!(:my_trip) { create(:trip, owner: owner, title: '自分の旅') }
    let!(:shared_trip) { create(:trip, title: '共有された旅') }
    let!(:other_trip) { create(:trip, title: '他人の旅') }

    before do
      TripUser.create!(trip: shared_trip, user: member, permission_level: 'viewer')
    end

    it '自分が所有している旅程が含まれること' do
      expect(Trip.shared_with_user(owner)).to include(my_trip)
    end

    it 'メンバーとして参加している旅程が含まれること' do
      expect(Trip.shared_with_user(member)).to include(shared_trip)
    end

    it '無関係な旅程は含まれないこと' do
      expect(Trip.shared_with_user(owner)).not_to include(other_trip)
      expect(Trip.shared_with_user(member)).not_to include(other_trip)
    end
  end

  describe 'メソッド: #clone_with_spots' do
    let(:original_trip) { create(:trip) }
    let(:new_owner) { create(:user) }

    before do
      original_trip.spots.create!(name: '観光地A', position: 1)
    end

    it '旅程が複製され、新しい所有者が設定されること' do
      cloned_trip = original_trip.clone_with_spots(new_owner)
      
      expect(cloned_trip).to be_persisted
      expect(cloned_trip.id).not_to eq original_trip.id
      expect(cloned_trip.owner).to eq new_owner
      expect(cloned_trip.title).to include(original_trip.title)
    end

    it '紐付いているスポットも複製されること' do
      cloned_trip = original_trip.clone_with_spots(new_owner)
      
      expect(cloned_trip.spots.count).to eq 1
      expect(cloned_trip.spots.first.name).to eq '観光地A'
      expect(cloned_trip.spots.first.id).not_to eq original_trip.spots.first.id
    end
  end
end