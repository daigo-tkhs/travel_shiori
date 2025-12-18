# frozen_string_literal: true

class Spot < ApplicationRecord
  belongs_to :trip

  # scopeを trip_id と day_number にすることで、同じ旅行の同じ日の中で順序を管理します
  acts_as_list scope: %i[trip_id day_number]

  # 保存・バリデーションの前に「予算」から数字以外の文字を掃除する
  before_validation :clean_estimated_cost

  # 緯度・経度が変更された場合に移動時間を計算するコールバック
  before_save :calculate_travel_time_from_previous, if: -> { (latitude_changed? || longitude_changed?) && geocoded? }

  enum :category, { sightseeing: 0, restaurant: 1, accommodation: 2, other: 3 }

  # バリデーション
  validates :name, presence: true, length: { maximum: 50 }
  # clean_estimated_cost のおかげで、ここでは純粋に整数チェックだけでOKになります
  validates :estimated_cost, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :travel_time, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  # 緯度・経度がセットされているか判定するヘルパー
  def geocoded?
    latitude.present? && longitude.present?
  end

  private

  # 「¥1,000」や「1,000円」といった入力を「1000」に変換する
  def clean_estimated_cost
    return if estimated_cost.blank?

    # 文字列として扱い、数字以外（¥ , 円など）をすべて削除して整数にする
    cleaned_value = estimated_cost.to_s.gsub(/[^0-9]/, '')
    self.estimated_cost = cleaned_value.to_i if cleaned_value.present?
  end

  def calculate_travel_time_from_previous
    previous_spot = higher_item
    return unless previous_spot&.geocoded? && geocoded?

    begin
      # TravelTimeService が定義されている前提
      self.travel_time = TravelTimeService.new.calculate_time(previous_spot, self)
    rescue => e
      Rails.logger.error "TravelTime calculation failed: #{e.message}"
    end
  end
end