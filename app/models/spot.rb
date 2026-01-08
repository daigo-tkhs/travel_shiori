# frozen_string_literal: true

class Spot < ApplicationRecord
  belongs_to :trip

  # scopeを trip_id と day_number にすることで、同じ旅行の同じ日の中で順序を管理します
  acts_as_list scope: %i[trip_id day_number]

  # 仮想属性
  attr_writer :duration_hours, :duration_minutes

  # 保存・バリデーションの前にデータを整形する
  before_validation :clean_estimated_cost
  before_validation :calculate_duration

  geocoded_by :name
  after_validation :geocode, if: ->(obj){ obj.name.present? }

  enum :category, { sightseeing: 0, restaurant: 1, accommodation: 2, other: 3 }

  # --- バリデーション ---
  validates :name, presence: { message: "を入力してください" }, length: { maximum: 50 }   
  validates :day_number, presence: { message: "を入力してください" }, numericality: { only_integer: true, greater_than: 0, message: "は1以上の数字で入力してください" }
  validates :estimated_cost, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :travel_time, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :duration, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  # 旅行期間外の日付入力を防ぐカスタムバリデーション
  validate :day_number_within_trip_dates

  # 緯度・経度がセットされているか判定するヘルパー
  def geocoded?
    latitude.present? && longitude.present?
  end

  # 時間・分の読み出し
  def duration_hours
    @duration_hours&.to_i || (duration.present? ? duration / 60 : 0)
  end

  def duration_minutes
    @duration_minutes&.to_i || (duration.present? ? duration % 60 : 0)
  end

  private

  def day_number_within_trip_dates
    return unless trip && trip.start_date && trip.end_date && day_number

    # 旅行の日数計算（終了日 - 開始日 + 1日）
    trip_days = (trip.end_date - trip.start_date).to_i + 1

    if day_number > trip_days
      errors.add(:day_number, "は旅行期間（#{trip_days}日間）以内で設定してください")
    end
  end

  def calculate_duration
    if @duration_hours.present? || @duration_minutes.present?
      self.duration = (@duration_hours.to_i * 60) + @duration_minutes.to_i
    end
  end

  def clean_estimated_cost
    return if estimated_cost.blank?
    self.estimated_cost = estimated_cost.to_s.gsub(/[^\d.]/, '').to_f.to_i
  end
end