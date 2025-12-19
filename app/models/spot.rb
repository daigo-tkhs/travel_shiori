# frozen_string_literal: true

class Spot < ApplicationRecord
  belongs_to :trip

  # scopeを trip_id と day_number にすることで、同じ旅行の同じ日の中で順序を管理します
  acts_as_list scope: %i[trip_id day_number]

  # 保存・バリデーションの前に「予算」から数字以外の文字を掃除する
  before_validation :clean_estimated_cost

  enum :category, { sightseeing: 0, restaurant: 1, accommodation: 2, other: 3 }

  
  # スポット名は必須
  validates :name, presence: { message: "を入力してください" }, length: { maximum: 50 }  
  validates :day_number, presence: { message: "を入力してください" }, numericality: { only_integer: true, greater_than: 0, message: "は1以上の数字で入力してください" }
  validates :estimated_cost, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :travel_time, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  # 緯度・経度がセットされているか判定するヘルパー
  def geocoded?
    latitude.present? && longitude.present?
  end

  private

  # 「¥1,000」や「2000.0」といった入力を「1000」「2000」に正しく変換する
  def clean_estimated_cost
    return if estimated_cost.blank?
    
    # 全角数字なども考慮する場合、一度文字列にして整形
    self.estimated_cost = estimated_cost.to_s.gsub(/[^\d.]/, '').to_f.to_i
  end

  # 注意: TravelTimeService はまだ作成していないため、
  # コールバックでの自動計算は削除し、コントローラー側の処理に任せます。
end