# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Message, type: :model do
  let(:message) { build(:message) }

  describe 'バリデーション' do
    # ------------------------------------------------------------------
    # 正常系
    # ------------------------------------------------------------------
    context '正常系' do
      it 'すべての値（trip, user, prompt）が正しく設定されていれば有効であること' do
        expect(message).to be_valid
      end

      it 'AIの回答(response)が空でも有効であること' do
        # ユーザーが送信した直後はAIの回答がまだない場合があるため
        message.response = nil
        expect(message).to be_valid
      end
    end

    # ------------------------------------------------------------------
    # 異常系: 必須項目
    # ------------------------------------------------------------------
    context '異常系: 必須項目' do
      it '旅程(trip)がない場合は無効であること' do
        message.trip = nil
        expect(message).to be_invalid
      end

      it 'ユーザー(user)がない場合は無効であること' do
        message.user = nil
        expect(message).to be_invalid
      end

      it '質問内容(prompt)がない場合は無効であること' do
        message.prompt = nil
        expect(message).to be_invalid
        expect(message.errors[:prompt]).to include("を入力してください")
      end

      it '質問内容(prompt)が空文字の場合は無効であること' do
        message.prompt = ""
        expect(message).to be_invalid
        expect(message.errors[:prompt]).to include("を入力してください")
      end
    end
  end

  # ------------------------------------------------------------------
  # 関連付けと削除
  # ------------------------------------------------------------------
  describe '関連付け' do
    it '旅程(trip)を削除すると、紐付いているメッセージも削除されること' do
      message.save!
      expect { message.trip.destroy }.to change(Message, :count).by(-1)
    end
  end
end