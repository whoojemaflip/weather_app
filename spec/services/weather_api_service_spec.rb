require 'rails_helper'

RSpec.describe WeatherApiService do
  let(:location) { 'London' }
  let(:api_key) { 'test_api_key' }

  before do
    allow(ENV).to receive(:[]).with('WEATHER_API_KEY').and_return(api_key)
  end

  describe '.fetch_forecast' do
    subject(:fetch_forecast) { described_class.fetch_forecast(location) }

    context 'when the API request is successful' do
      let(:successful_response) do
        {
          'location' => {
            'name' => 'London',
            'country' => 'United Kingdom',
            'localtime' => '2024-03-29 20:00'
          },
          'current' => {
            'temp_c' => 15.0,
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
                  'maxtemp_c' => 18.0,
                  'mintemp_c' => 12.0,
                  'condition' => {
                    'text' => 'Partly cloudy',
                    'icon' => '//cdn.weatherapi.com/weather/64x64/day/116.png'
                  }
                }
              }
            ]
          }
        }
      end

      before do
        stub_request(:get, /api.weatherapi.com/)
          .with(query: hash_including(key: api_key, q: location))
          .to_return(
            status: 200,
            body: successful_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns parsed weather data' do
        expect(subject).to include(
          location: {
            name: 'London',
            country: 'United Kingdom',
            local_time: '2024-03-29 20:00'
          },
          current: {
            temperature: 15.0,
            condition: 'Partly cloudy',
            icon: '//cdn.weatherapi.com/weather/64x64/day/116.png'
          }
        )
      end

      it 'caches the response' do
        expect(Rails.cache).to receive(:fetch)
          .with("weather_forecast_#{location.downcase}", expires_in: 30.minutes)
          .and_call_original

        fetch_forecast
      end
    end

    context 'when the location is not found' do
      before do
        stub_request(:get, /api.weatherapi.com/)
          .with(query: hash_including(key: api_key, q: location))
          .to_return(status: 400)
      end

      it 'raises InvalidLocationError' do
        expect { subject }
          .to raise_error(WeatherApiService::InvalidLocationError)
      end
    end

    context 'when the API request fails' do
      before do
        stub_request(:get, /api.weatherapi.com/)
          .with(query: hash_including(key: api_key, q: location))
          .to_return(status: 500, body: 'Internal Server Error')
      end

      it 'raises ApiError' do
        expect { subject }
          .to raise_error(WeatherApiService::ApiError)
      end
    end

    context 'when the response is invalid JSON' do
      before do
        stub_request(:get, /api.weatherapi.com/)
          .with(query: hash_including(key: api_key, q: location))
          .to_return(status: 200, body: 'Invalid JSON')
      end

      it 'raises ApiError' do
        expect { subject }
          .to raise_error(WeatherApiService::ApiError)
      end
    end
  end
end
