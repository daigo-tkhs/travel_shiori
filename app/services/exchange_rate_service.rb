# frozen_string_literal: true

class ExchangeRateService
  BASE_URL = "https://v6.exchangerate-api.com/v6"
  DEFAULT_RATE = 150.0
  CACHE_KEY = "exchange_rate_usd_to_jpy"
  CACHE_TTL = 12.hours

  # USD→JPYのレートを取得（12時間キャッシュ）
  def self.fetch_usd_to_jpy
    Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_TTL) do
      fetch_from_api
    end
  end

  def self.fetch_from_api
    api_key = ENV["EXCHANGE_RATE_API_KEY"]
    unless api_key.present?
      Rails.logger.warn "ExchangeRateService: EXCHANGE_RATE_API_KEY is not set. Using default rate."
      return DEFAULT_RATE
    end

    uri = URI("#{BASE_URL}/#{api_key}/pair/USD/JPY")
    response = Net::HTTP.get_response(uri)

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error "ExchangeRateService: HTTP #{response.code} returned."
      return DEFAULT_RATE
    end

    data = JSON.parse(response.body)

    if data["result"] == "success"
      data["conversion_rate"].to_f
    else
      Rails.logger.error "ExchangeRateService: API error - #{data['error-type']}"
      DEFAULT_RATE
    end
  rescue StandardError => e
    Rails.logger.error "ExchangeRateService: #{e.class} - #{e.message}"
    DEFAULT_RATE
  end

  private_class_method :fetch_from_api
end
