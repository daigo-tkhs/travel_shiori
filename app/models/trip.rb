class Trip < ApplicationRecord
  # 存在性の検証（必須項目）
  validates :title, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true # ★追加: 終了日を必須にする
  validates :total_budget, presence: true
  validates :travel_theme, presence: true

  # データ型の検証
  validates :total_budget, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  
  # カスタム検証: 終了日は開始日以降であること
  validate :end_date_after_start_date

  # 関連付け
  belongs_to :owner, class_name: 'User', foreign_key: 'owner_id'
  has_many :spots, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :checklist_items, dependent: :destroy
  has_many :trip_users, dependent: :destroy
  has_many :users, through: :trip_users
  
  # お気に入り機能
  has_many :favorites, dependent: :destroy
  has_many :favorited_users, through: :favorites, source: :user

  # スコープ
  scope :shared_with_user, ->(user) do
    joins(:trip_users).where('trip_users.user_id = ?', user.id).distinct
  end
  scope :owned_by_user, ->(user) { where(owner: user) }
  
  # 権限チェック用メソッド
  def owner?(user)
    trip_users.find_by(user: user)&.owner?
  end

  def editable_by?(user)
    tu = trip_users.find_by(user: user)
    tu && (tu.owner? || tu.editor?)
  end

  def viewable_by?(user)
    trip_users.exists?(user: user)
  end

  def favorited_by?(user)
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

    if end_date < start_date
      errors.add(:end_date, "は開始日より後の日付を選択してください")
    end
  end
end