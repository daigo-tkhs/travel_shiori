# app/models/trip.rb

class Trip < ApplicationRecord
  # 旅程の作成者（オーナー）とのカスタム関連付け
  belongs_to :owner, class_name: 'User', foreign_key: 'owner_id'

  # 1対多の関連付け
  has_many :spots, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :checklist_items, dependent: :destroy

  # 共有ユーザーとの多対多の関連付け
  has_many :trip_users, dependent: :destroy
  has_many :users, through: :trip_users
end