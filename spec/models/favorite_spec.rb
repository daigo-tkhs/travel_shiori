# spec/models/favorite_spec.rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Favorite, type: :model do
  let(:favorite) { build(:favorite) }

  describe 'バリデーション' do
    context '正常系' do
      it '旅程とユーザーが紐付いていれば有効であること' do
        expect(favorite).to be_valid
      end
    end

    context '異常系: 必須項目' do
      it '旅程(trip)がない場合は無効であること' do
        favorite.trip = nil
        expect(favorite).to be_invalid
      end

      it 'ユーザー(user)がない場合は無効であること' do
        favorite.user = nil
        expect(favorite).to be_invalid
      end
    end

    context '異常系: 重複チェック' do
      it '同じユーザーが同じ旅程を重複してお気に入り登録できないこと' do
        # 1回目を保存
        favorite.save!
        
        # 全く同じ組み合わせで2回目を作成
        duplicate_favorite = build(:favorite, user: favorite.user, trip: favorite.trip)
        
        expect(duplicate_favorite).to be_invalid
        # 一意性制約エラー（文言はRails標準）
        expect(duplicate_favorite.errors[:user_id]).to include("はすでに存在します")
      end
    end
  end
end