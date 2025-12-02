class TravelTimeService
  def initialize
    # オプションを削除し、キーのみ渡す（これが修正のキモです）
    @client = GoogleMapsService::Client.new(
      key: Rails.application.credentials.google_maps[:api_key]
    )
  end

  # 2地点間の移動時間を計算（単位: 分）
  def calculate_time(origin_spot, destination_spot)
    return nil unless origin_spot.geocoded? && destination_spot.geocoded?

    routes = @client.directions(
      "#{origin_spot.latitude},#{origin_spot.longitude}",
      "#{destination_spot.latitude},#{destination_spot.longitude}",
      mode: "driving",
      language: "ja"
    )

    return nil if routes.empty?

    duration_seconds = routes[0][:legs][0][:duration][:value]
    (duration_seconds / 60.0).round
  rescue => e
    Rails.logger.error "TravelTimeService Error: #{e.message}"
    nil
  end
end
