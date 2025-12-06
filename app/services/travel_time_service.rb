require 'net/http'
require 'json'
require 'uri'

class TravelTimeService
  def initialize
    @api_key = Rails.application.credentials.google_maps[:api_key]
    @base_url = "https://maps.googleapis.com/maps/api/directions/json"
  end

  # 2地点間の移動時間を計算（単位: 分）
  def calculate_time(origin_spot, destination_spot)
    # 緯度経度がない場合は計算不可
    return nil unless origin_spot.geocoded? && destination_spot.geocoded?

    # URLパラメータの作成
    params = {
      origin: "#{origin_spot.latitude},#{origin_spot.longitude}",
      destination: "#{destination_spot.latitude},#{destination_spot.longitude}",
      mode: 'driving',
      language: 'ja',
      key: @api_key
    }

    # クエリ文字列の生成
    uri = URI(@base_url)
    uri.query = URI.encode_www_form(params)

    # APIリクエスト送信
    response = Net::HTTP.get_response(uri)

    # 成功時のみ処理
    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      
      # ルートが見つかった場合
      if data['routes'].present? && data['routes'][0]['legs'].present?
        # 秒数を取得
        duration_seconds = data['routes'][0]['legs'][0]['duration']['value']
        # 分に変換して四捨五入
        return (duration_seconds / 60.0).round
      end
    end

    nil
  rescue => e
    Rails.logger.error "TravelTimeService HTTP Error: #{e.message}"
    nil
  end
end