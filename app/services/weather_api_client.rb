require "net/http"
require "json"
require "uri"

class WeatherApiClient
  class Error < StandardError; end
  class InvalidLocationError < Error; end
  class ApiError < Error; end

  BASE_URL = "http://api.weatherapi.com/v1"

  def initialize(api_key: ENV["WEATHER_API_KEY"])
    @api_key = api_key
  end

  def fetch_current_weather(location)
    response = make_request(location)
    parse_response(response)
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    raise ApiError, "Request timed out: #{e.message}"
  rescue JSON::ParserError => e
    raise ApiError, "Invalid response format: #{e.message}"
  end

  private

  def make_request(location)
    uri = URI("#{BASE_URL}/forecast.json")
    uri.query = URI.encode_www_form(
      key: @api_key,
      q: location,
      days: 1
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

  def parse_response(response_body)
    data = JSON.parse(response_body)
    current_day = data["forecast"]["forecastday"].first

    WeatherForecast.new(
      location: data["location"]["name"],
      current_temp: data["current"]["temp_f"],
      high_temp: current_day["day"]["maxtemp_f"],
      low_temp: current_day["day"]["mintemp_f"],
      conditions: data["current"]["condition"]["text"]
    )
  end
end
