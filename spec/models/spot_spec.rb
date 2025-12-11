# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spot, type: :model do
  let(:spot) { build(:spot) }

  describe 'バリデーション' do
    # ------------------------------------------------------------------
    # 正常系
    # ------------------------------------------------------------------
    context '正常系' do
      it 'すべての値が正しく設定されていれば有効であること' do
        expect(spot).to be_valid
      end
    end

    # ------------------------------------------------------------------
    # 異常系: 必須項目
    # ------------------------------------------------------------------
    context '異常系: 必須項目' do
      it '旅程(trip)がない場合は無効であること' do
        spot.trip = nil
        expect(spot).to be_invalid
      end

      it 'スポット名(name)がない場合は無効であること' do
        spot.name = nil
        expect(spot).to be_invalid
        expect(spot.errors[:name]).to include("を入力してください")
      end
    end

    # ------------------------------------------------------------------
    # 異常系: 文字数制限
    # ------------------------------------------------------------------
    context '異常系: 文字数制限' do
      it 'スポット名(name)が長すぎる場合（例: 51文字以上）は無効であること' do
        spot.name = 'a' * 51
        expect(spot).to be_invalid
        expect(spot.errors[:name]).to include("は50文字以内で入力してください") 
      end
    end

    # ------------------------------------------------------------------
    # 異常系: 数値チェック
    # ------------------------------------------------------------------
    context '異常系: 数値チェック' do
      it '費用(estimated_cost)が負の数の場合は無効であること' do
        spot.estimated_cost = -100
        expect(spot).to be_invalid
      end

      it '費用(estimated_cost)が小数の場合は無効であること' do
        spot.estimated_cost = 100.5
        expect(spot).to be_invalid
      end

      it '所要時間(travel_time)が負の数の場合は無効であること' do
        spot.travel_time = -10
        expect(spot).to be_invalid
      end

      it '所要時間(travel_time)が小数の場合は無効であること' do
        spot.travel_time = 10.5
        expect(spot).to be_invalid
      end
    end
  end

  describe '関連付け' do
    it '旅程(trip)に属していること' do
      association = described_class.reflect_on_association(:trip)
      expect(association.macro).to eq :belongs_to
    end
  end
end