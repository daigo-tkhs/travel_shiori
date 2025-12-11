# frozen_string_literal: true

class Trip < ApplicationRecord
  # has_one_attached :image

  # 存在性の検証（必須項目）
  validates :title, presence: true, length: { maximum: 100 }
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :total_budget, presence: true
  validates :travel_theme, presence: true

  # データ型の検証
  validates :total_budget, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # カスタム検証: 終了日は開始日以降であること
  validate :end_date_after_start_date

  # 関連付け
  belongs_to :owner, class_name: 'User'
  has_many :spots, dependent: :destroy
  has_many :messages, dependent: :destroy
  
  # ▼▼▼ 修正: 存在しない has_one :checklist を削除しました ▼▼▼
  has_many :checklist_items, dependent: :destroy
  
  has_many :trip_users, dependent: :destroy
  has_many :users, through: :trip_users
  has_many :trip_invitations, dependent: :destroy

  # お気に入り機能
  has_many :favorites, dependent: :destroy
  has_many :favorited_users, through: :favorites, source: :user

  # スコープ
  scope :shared_with_user, lambda { |user|
    joins(:trip_users).where(trip_users: { user_id: user.id }).distinct
  }
  scope :owned_by_user, ->(user) { where(owner: user) }

  # 権限チェック用メソッド
  def owner?(user)
    return false if user.nil?

    owner_id == user.id
  end

  def editable_by?(user)
    return true if owner?(user)

    tu = trip_users.find_by(user: user)
    tu&.editor?
  end

  def viewable_by?(user)
    # trip_usersが存在するかでチェック
    trip_users.exists?(user: user)
  end

  def favorited_by?(user)
    return false if user.nil? # ゲストなら「お気に入り」判定をfalseにする

    favorites.exists?(user_id: user.id)
  end

  # コールバック
  after_create :set_owner_as_trip_user

  private

  def set_owner_as_trip_user
    trip_users.create!(user: owner, permission_level: :owner)
  end

  # 終了日が開始日より前にならないようにチェック
  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    return unless end_date < start_date

    errors.add(:end_date, 'は開始日より後の日付を選択してください')
  end
end