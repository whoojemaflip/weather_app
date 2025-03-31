require "time"

class WeatherApiService
  include ActiveModel::Model
  include ActiveModel::Validations

  SuccessResponse = Data.define(:forecast) do
    def success? = true
  end

  ErrorResponse = Data.define(:error_message) do
    def success? = false
  end

  CACHE_DURATION = 30.minutes

  attr_reader :location, :client

  validates :location, presence: true
  validate :valid_us_zip_code

  def initialize(location:, client: WeatherApiClient.new)
    @location = location
    @client = client
  end

  def fetch_forecast
    Rails.cache.fetch(cache_key, expires_in: CACHE_DURATION) do
      weather_forecast = client.fetch_current_weather(location)
      SuccessResponse.new(forecast: weather_forecast)
    end
  rescue WeatherApiClient::Error => e
    ErrorResponse.new(error_message: e.message)
  end

  private

  def valid_us_zip_code
    return if location.blank?

    unless location.match?(/^\d{5}(-\d{4})?$/)
      errors.add(:location, "must be a valid US zip code (e.g., 12345 or 12345-6789)")
    end
  end

  def cache_key
    "weather_forecast_#{location.downcase.gsub(/[^a-z0-9]/, '_')}"
  end
end
