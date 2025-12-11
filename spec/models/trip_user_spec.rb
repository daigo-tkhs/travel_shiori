# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TripUser, type: :model do
  let(:trip_user) { build(:trip_user) }

  describe 'バリデーション' do
    # ------------------------------------------------------------------
    # 正常系
    # ------------------------------------------------------------------
    context '正常系' do
      it 'すべての値（trip, user, permission_level）が正しく設定されていれば有効であること' do
        expect(trip_user).to be_valid
      end

      it 'permission_level が "viewer" (閲覧者) であれば有効であること' do
        trip_user.permission_level = 'viewer'
        expect(trip_user).to be_valid
      end

      it 'permission_level が "editor" (編集者) であれば有効であること' do
        trip_user.permission_level = 'editor'
        expect(trip_user).to be_valid
      end

      it 'permission_level が "owner" (所有者) であれば有効であること' do
        trip_user.permission_level = 'owner'
        expect(trip_user).to be_valid
      end
    end

    # ------------------------------------------------------------------
    # 異常系: 必須項目
    # ------------------------------------------------------------------
    context '異常系: 必須項目の欠如' do
      it '旅程(trip)がない場合は無効であること' do
        trip_user.trip = nil
        expect(trip_user).to be_invalid
      end

      it 'ユーザー(user)がない場合は無効であること' do
        trip_user.user = nil
        expect(trip_user).to be_invalid
      end

      it '権限(permission_level)がない場合は無効であること' do
        trip_user.permission_level = nil
        expect(trip_user).to be_invalid
        expect(trip_user.errors[:permission_level]).to include("を入力してください")
      end
    end

    # ------------------------------------------------------------------
    # 異常系: 重複・不正値
    # ------------------------------------------------------------------
    context '異常系: 整合性チェック' do
      it '同じ旅程に同じユーザーを重複して登録できないこと' do
        trip_user.save!
        
        # 全く同じ組み合わせの2つ目を作成
        duplicate_trip_user = build(:trip_user, trip: trip_user.trip, user: trip_user.user)
        
        expect(duplicate_trip_user).to be_invalid
        expect(duplicate_trip_user.errors[:user_id]).to include("はすでに存在します")
      end

      it 'permission_level に不正な値（例: "admin"）が入らないこと' do
        # Enumを使用している場合、定義外の値を入れると ArgumentError になるはず
        expect { trip_user.permission_level = 'admin' }.to raise_error(ArgumentError)
      end
    end
  end
end