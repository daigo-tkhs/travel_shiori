# app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :nickname, presence: true
  has_many :owned_trips, class_name: 'Trip', foreign_key: 'owner_id', dependent: :destroy
  has_many :trip_users, dependent: :destroy
  has_many :trips, through: :trip_users

end