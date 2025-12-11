# frozen_string_literal: true

class Spot < ApplicationRecord
  belongs_to :trip
  acts_as_list scope: %i[trip_id day_number]
  before_save :set_position, if: :new_record?
  before_save :calculate_travel_time_from_previous, if: -> { saved_change_to_latitude? || saved_change_to_longitude? }

  enum :category, { sightseeing: 0, restaurant: 1, accommodation: 2, other: 3 }

  # バリデーション
  validates :name, presence: true, length: { maximum: 50 }
  validates :estimated_cost, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :travel_time, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  private

  def set_position
    return if position.present?

    # Trip全体の最大値を取得して末尾に追加
    max_position = trip.spots.maximum(:position) || 0
    self.position = max_position + 1
  end

  # Metrics解消のためロジックを分離
  def calculate_travel_time_from_previous
    previous_spot = find_previous_spot
    return 0 unless previous_spot&.geocoded? && geocoded?

    self.travel_time = TravelTimeService.new.calculate_time(previous_spot, self)
  rescue StandardError => e
    Rails.logger.error "TravelTime calculation failed: #{e.message}"
    self.travel_time = 0
  end

  # Metrics解消のため、前後のスポット検索ロジックを分離
  def find_previous_spot
    current_pos = position || (trip.spots.where(day_number: day_number).maximum(:position).to_i + 1)

    trip.spots
        .where(day_number: day_number)
        .where(position: ...current_pos)
        .order(position: :desc)
        .first
  end
end
