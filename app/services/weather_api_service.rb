require 'net/http'
require 'json'
require 'uri'
require 'time'

class WeatherApiService
  class Error < StandardError; end
  class InvalidLocationError < Error; end
  class ApiError < Error; end

  BASE_URL = "http://api.weatherapi.com/v1"
  CACHE_DURATION = 30.minutes

  def self.fetch_forecast(location)
    Rails.cache.fetch(cache_key(location), expires_in: CACHE_DURATION) do
      response = make_request(location)
      parse_response(response)
    end
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    raise ApiError, "Request timed out: #{e.message}"
  rescue JSON::ParserError => e
    raise ApiError, "Invalid response format: #{e.message}"
  end

  private

  def self.make_request(location)
    uri = URI("#{BASE_URL}/current.json")
    uri.query = URI.encode_www_form(
      key: ENV["WEATHER_API_KEY"],
      q: location
    )

    response = Net::HTTP.get_response(uri)

    case response
    when Net::HTTPSuccess
      response.body
    when Net::HTTPNotFound, Net::HTTPBadRequest
      raise InvalidLocationError, "Location not found: #{location}"
    else
      raise ApiError, "API request failed: #{response.code} - #{response.message}"
    end
  end

  def self.parse_response(response_body)
    data = JSON.parse(response_body)

    {
      location: {
        name: data["location"]["name"],
        country: data["location"]["country"],
        local_time: data["location"]["localtime"]
      },
      current: {
        temperature: data["current"]["temp_c"],
        condition: data["current"]["condition"]["text"],
        icon: data["current"]["condition"]["icon"]
      }
    }
  end

  def self.cache_key(location)
    "weather_forecast_#{location.downcase.gsub(/[^a-z0-9]/, '_')}"
  end
end
