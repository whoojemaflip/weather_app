require "time"

class WeatherService
  include ActiveModel::Model
  include ActiveModel::Validations

  SuccessResponse = Data.define(:forecast, :from_cache) do
    def success? = true
  end

  ErrorResponse = Data.define(:error_message) do
    def success? = false
  end

  CACHE_DURATION = 30.minutes

  attr_reader :location, :client, :cache

  validates :location, presence: true
  validate :valid_us_zip_code

  def self.call(location)
    service = new(location: location)
    if service.valid?
      service.fetch_forecast
    else
      ErrorResponse.new(error_message: service.errors.full_messages.join(", "))
    end
  end

  def initialize(location: nil, client: nil)
    @location = location
    @client = client || WeatherApiClient.new
    @cache = Rails.cache
  end

  def fetch_forecast
    if cached_forecast = cache.read(cache_key)
      return SuccessResponse.new(forecast: cached_forecast, from_cache: true)
    end

    forecast = client.fetch_current_weather(location)
    cache.write(cache_key, forecast, expires_in: CACHE_DURATION)

    SuccessResponse.new(forecast: forecast, from_cache: false)
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
