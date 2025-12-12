# spec/models/checklist_item_spec.rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChecklistItem, type: :model do
  let(:checklist_item) { build(:checklist_item) }

  describe 'バリデーション' do
    context '正常系' do
      it 'すべての値が正しく設定されていれば有効であること' do
        expect(checklist_item).to be_valid
      end
    end

    context '異常系' do
      it '名前(name)がない場合は無効であること' do
        checklist_item.name = nil
        expect(checklist_item).to be_invalid
        expect(checklist_item.errors[:name]).to include("を入力してください")
      end

      it '旅程(trip)がない場合は無効であること' do
        checklist_item.trip = nil
        expect(checklist_item).to be_invalid
      end
    end
  end
end