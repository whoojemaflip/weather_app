require 'rails_helper'

RSpec.describe WeatherApiClient do
  let(:api_key) { 'test_api_key' }
  let(:location) { '12345' }
  let(:client) { described_class.new(api_key: api_key) }

  describe '#fetch_current_weather' do
    subject(:fetch_weather) { client.fetch_current_weather(location) }

    context 'when the API request is successful' do
      let(:successful_response) do
        {
          'location' => {
            'name' => 'New York',
            'country' => 'United States',
            'localtime' => '2024-03-29 20:00'
          },
          'current' => {
            'temp_f' => 59.0,
            'condition' => {
              'text' => 'Partly cloudy',
              'icon' => '//cdn.weatherapi.com/weather/64x64/day/116.png'
            }
          },
          'forecast' => {
            'forecastday' => [
              {
                'date' => '2024-03-29',
                'day' => {
                  'maxtemp_f' => 68.0,
                  'mintemp_f' => 50.0,
                  'condition' => {
                    'text' => 'Sunny'
                  }
                }
              }
            ]
          }
        }
      end

      before do
        stub_request(:get, "http://api.weatherapi.com/v1/forecast.json?days=1&key=#{api_key}&q=#{location}")
          .to_return(
            status: 200,
            body: successful_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns a WeatherForecast object' do
        result = fetch_weather
        expect(result).to be_a(WeatherForecast)
      end

      it 'sets the location correctly' do
        result = fetch_weather
        expect(result.location).to eq('New York')
      end

      it 'sets the current temperature correctly' do
        result = fetch_weather
        expect(result.current_temp).to eq(59.0)
      end

      it 'sets the high temperature correctly' do
        result = fetch_weather
        expect(result.high_temp).to eq(68.0)
      end

      it 'sets the low temperature correctly' do
        result = fetch_weather
        expect(result.low_temp).to eq(50.0)
      end

      it 'sets the conditions correctly' do
        result = fetch_weather
        expect(result.conditions).to eq('Partly cloudy')
      end
    end

    context 'when the location is not found' do
      before do
        stub_request(:get, "http://api.weatherapi.com/v1/forecast.json?days=1&key=#{api_key}&q=#{location}")
          .to_return(status: 400)
      end

      it 'raises InvalidLocationError' do
        expect { subject }
          .to raise_error(WeatherApiClient::InvalidLocationError)
      end
    end

    context 'when the API returns a server error' do
      before do
        stub_request(:get, "http://api.weatherapi.com/v1/forecast.json?days=1&key=#{api_key}&q=#{location}")
          .to_return(status: 500, body: 'Internal Server Error')
      end

      it 'raises ApiError' do
        expect { subject }
          .to raise_error(WeatherApiClient::ApiError)
      end
    end

    context 'when the response is invalid JSON' do
      before do
        stub_request(:get, "http://api.weatherapi.com/v1/forecast.json?days=1&key=#{api_key}&q=#{location}")
          .to_return(status: 200, body: 'Invalid JSON')
      end

      it 'raises ApiError' do
        expect { subject }
          .to raise_error(WeatherApiClient::ApiError)
      end
    end
  end
end
