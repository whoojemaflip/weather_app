require 'rails_helper'

RSpec.describe WeatherApiService do
  let(:location) { '12345' }
  let(:client) { instance_double(WeatherApiClient) }
  let(:service) { described_class.new(location: location, client: client) }

  describe 'validations' do
    context 'when location is a valid 5-digit zip code' do
      let(:location) { '12345' }

      it 'is valid' do
        expect(service).to be_valid
      end
    end

    context 'when location is a valid 5+4 zip code' do
      let(:location) { '12345-6789' }

      it 'is valid' do
        expect(service).to be_valid
      end
    end

    context 'when location is not a valid zip code' do
      let(:location) { 'London' }

      it 'is invalid' do
        expect(service).not_to be_valid
      end

      it 'has the correct error message' do
        service.valid?
        expect(service.errors[:location]).to include('must be a valid US zip code (e.g., 12345 or 12345-6789)')
      end
    end

    context 'when location is blank' do
      let(:location) { '' }

      it 'is invalid' do
        expect(service).not_to be_valid
      end

      it 'has the correct error message' do
        service.valid?
        expect(service.errors[:location]).to include("can't be blank")
      end
    end
  end

  describe '#fetch_forecast' do
    subject(:fetch_forecast) { service.fetch_forecast }

    let(:weather_forecast) do
      WeatherForecast.new(
        location: 'New York',
        current_temp: 15.0,
        high_temp: 20.0,
        low_temp: 10.0,
        conditions: 'Partly cloudy'
      )
    end

    context 'when the API request is successful' do
      before do
        allow(client).to receive(:fetch_current_weather).with(location).and_return(weather_forecast)
      end

      it 'returns a SuccessResponse' do
        result = subject
        expect(result).to be_a(WeatherApiService::SuccessResponse)
      end

      it 'has success? returning true' do
        result = subject
        expect(result.success?).to be true
      end

      it 'contains the WeatherForecast from the client' do
        result = subject
        expect(result.forecast).to eq(weather_forecast)
      end

      it 'caches the response with the correct key' do
        expect(Rails.cache).to receive(:fetch)
          .with("weather_forecast_#{location.downcase}", expires_in: 30.minutes)
          .and_call_original

        fetch_forecast
      end

      it 'uses the client to fetch weather data' do
        expect(client).to receive(:fetch_current_weather).with(location)
        fetch_forecast
      end
    end

    context 'when the client raises an error' do
      before do
        allow(client).to receive(:fetch_current_weather)
          .with(location)
          .and_raise(WeatherApiClient::Error.new('API Error'))
      end

      it 'returns an ErrorResponse' do
        result = subject
        expect(result).to be_a(WeatherApiService::ErrorResponse)
      end

      it 'has success? returning false' do
        result = subject
        expect(result.success?).to be false
      end

      it 'contains the correct error message' do
        result = subject
        expect(result.error_message).to eq('API Error')
      end
    end
  end
end
