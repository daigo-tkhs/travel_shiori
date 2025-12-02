class Spot < ApplicationRecord
  belongs_to :trip
  # scope: [:trip_id, :day_number] -> 「同じ旅程」かつ「同じ日」の中で順番を管理する
  acts_as_list scope: [:trip_id, :day_number]
  
  # バリデーション
  validates :name, presence: true
  # ★修正: day_number を必須(presence: true)に変更し、空のデータが登録できないようにブロックする
  validates :day_number, presence: true, numericality: { only_integer: true, greater_than: 0 }
  
  # --- Geocoder (緯度経度自動取得) ---
  geocoded_by :name
  after_validation :geocode, if: :will_save_change_to_name?

  # --- コールバック ---
  # 1. 作成時に順番(position)をセット
  before_create :set_default_position
  
  # 2. 保存前に前のスポットとの移動時間を計算してセット
  before_save :calculate_travel_time_from_previous
  
  private

  # positionが設定されていない場合、そのTripの最大position + 1 を設定する
  def set_default_position
    unless self.position.present?
      # Trip全体の最大値を取得して末尾に追加
      max_position = self.trip.spots.maximum(:position) || 0
      self.position = max_position + 1
    end
  end

  # 一つ前のスポットとの移動時間を計算して保存する
  def calculate_travel_time_from_previous
    # 緯度経度がない場合は計算できないのでスキップ
    return unless geocoded?

    # 現在のスポットの仮のpositionを決定
    current_pos = self.position || (self.trip.spots.where(day_number: day_number).maximum(:position).to_i + 1)

    # 「同じ日」の中で、「自分より前」にある、「一番近い」スポットを探す
    previous_spot = self.trip.spots
                        .where(day_number: day_number)
                        .where("position < ?", current_pos)
                        .order(position: :desc)
                        .first

    if previous_spot && previous_spot.geocoded?
      service = TravelTimeService.new
      time = service.calculate_time(previous_spot, self)
      self.travel_time = time if time
    else
      # 前のスポットがない（その日の1番目）場合は 0分
      self.travel_time = 0
    end
  rescue => e
    Rails.logger.error "Failed to calculate travel time: #{e.message}"
  end
end