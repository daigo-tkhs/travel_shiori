# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TripInvitation, type: :model do
  # テストデータの準備
  let(:trip) { create(:trip) }
  let(:sender) { create(:user) }
  let(:invitation) { build(:trip_invitation, trip: trip, sender: sender) }

  describe 'バリデーション' do
    # ------------------------------------------------------------------
    # 正常系
    # ------------------------------------------------------------------
    context '正常系' do
      it 'すべての値が正しく設定されていれば有効であること' do
        expect(invitation).to be_valid
      end
      
      it 'トークンと有効期限が空でも、保存時に自動生成されて有効になること' do
        invitation.token = nil
        invitation.expires_at = nil
        expect(invitation).to be_valid
        expect(invitation.token).not_to be_nil
        expect(invitation.expires_at).not_to be_nil
      end
    end

    # ------------------------------------------------------------------
    # 異常系: 必須項目
    # ------------------------------------------------------------------
    context '異常系: 必須項目の欠如' do
      it 'メールアドレスがない場合は無効であること' do
        invitation.email = nil
        expect(invitation).to be_invalid
        expect(invitation.errors[:email]).to include("を入力してください")
      end

      it '権限(role)がない場合は無効であること' do
        invitation.role = nil
        expect(invitation).to be_invalid
        expect(invitation.errors[:role]).to include("を入力してください")
      end

      it '旅程(trip)がない場合は無効であること' do
        invitation.trip = nil
        expect(invitation).to be_invalid
      end

      it '招待者(sender)がない場合は無効であること' do
        invitation.sender = nil
        expect(invitation).to be_invalid
      end
    end

    # ------------------------------------------------------------------
    # 異常系: 不正な値・形式
    # ------------------------------------------------------------------
    context '異常系: 不正な値' do
      it 'メールアドレスの形式が不正な場合は無効であること' do
        invalid_emails = %w[plainaddress #@%^%#$@#$@.com @example.com email.example.com]
        invalid_emails.each do |invalid_email|
          invitation.email = invalid_email
          expect(invitation).to be_invalid, "#{invalid_email.inspect} should be invalid"
          expect(invitation.errors[:email]).to include("は不正な値です")
        end
      end

      it 'roleが不正な値の場合は ArgumentError が発生すること' do
        expect { invitation.role = 'admin' }.to raise_error(ArgumentError)
      end

      it 'トークンが重複している場合は無効であること' do
        create(:trip_invitation, token: 'duplicate_token')
        invitation.token = 'duplicate_token'
        expect(invitation).to be_invalid
        expect(invitation.errors[:token]).to include("はすでに存在します")
      end
    end
  end

  describe 'カスタムメソッド' do
    describe '#expired?' do
      it '有効期限が過去の場合は true を返すこと' do
        invitation.expires_at = 1.minute.ago
        expect(invitation.expired?).to be true
      end

      it '有効期限が未来の場合は false を返すこと' do
        invitation.expires_at = 1.minute.from_now
        expect(invitation.expired?).to be false
      end
    end

    describe '#valid_invitation?' do
      it '期限内かつ未使用なら true を返すこと' do
        invitation.expires_at = 1.day.from_now
        invitation.accepted_at = nil
        expect(invitation.valid_invitation?).to be true
      end

      it '期限切れなら false を返すこと' do
        invitation.expires_at = 1.day.ago
        expect(invitation.valid_invitation?).to be false
      end

      it '使用済みなら false を返すこと' do
        invitation.expires_at = 1.day.from_now
        invitation.accepted_at = Time.current
        expect(invitation.valid_invitation?).to be false
      end
    end
  end
end