# frozen_string_literal: true

class TripInvitation < ApplicationRecord
  belongs_to :trip
  belongs_to :sender, class_name: 'User', foreign_key: 'sender_id'
  belongs_to :user, optional: true

  # 権限定義（TripUserと合わせる想定ですが、ここではシンプルに定義）
  # 0: 閲覧者, 1: 編集者
  enum :role, { viewer: 0, editor: 1 }

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, presence: true

  # 修正: 作成時にトークンと有効期限をセット (before_validationに変更し、統合)
  before_validation :setup_invitation_data, on: :create

  # --- 判定メソッド ---

  # 有効期限切れか？
  def expired?
    expires_at < Time.current
  end

  # すでに使用済み（参加済み）か？
  def accepted?
    accepted_at.present?
  end

  # 有効な招待状か？
  def valid_invitation?
    !expired? && !accepted?
  end

  private

  # 修正: 統合されたセットアップメソッド
  def setup_invitation_data
    # URLで安全に使えるランダムな文字列（32文字程度）を生成
    self.token ||= SecureRandom.urlsafe_base64(24)
    # 有効期限を7日後に設定
    self.expires_at ||= 7.days.from_now
  end
end