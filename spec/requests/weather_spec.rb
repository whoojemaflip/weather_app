require 'rails_helper'

RSpec.describe "Weather", type: :request do
  describe "GET /" do
    it "renders the new form" do
      get root_path
      expect(response.body).to include("Weather Forecast")
    end
  end

  describe "POST /weather" do
    context "with valid location" do
      let(:forecast) do
        WeatherForecast.new(
          location: "90210",
          current_temp: 20,
          high_temp: 25,
          low_temp: 15,
          conditions: "Sunny"
        )
      end

      let(:success_response) do
        WeatherService::SuccessResponse.new(forecast:, from_cache: false)
      end

      before do
        allow(WeatherService).to receive(:call)
          .with("90210")
          .and_return(success_response)
      end

      it "creates a forecast and shows the result" do
        post weather_index_path, params: { weather_service: { location: "90210" } }

        expect(response.body).to include("Weather in 90210")
        expect(response.body).to include("20°F")
        expect(response.body).to include("25°F")
        expect(response.body).to include("15°F")
        expect(response.body).to include("Sunny")
      end

      context "when the forecast is cached" do
        let(:success_response) do
          WeatherService::SuccessResponse.new(forecast:, from_cache: true)
        end

        it "shows the cached forecast" do
          post weather_index_path, params: { weather_service: { location: "90210" } }

          expect(response.body).to include("(From cache)")
        end
      end
    end

    context "with invalid location" do
      let(:error_response) do
        WeatherService::ErrorResponse.new("Invalid zip code format")
      end

      before do
        allow(WeatherService).to receive(:call)
          .with("invalid")
          .and_return(error_response)
      end

      it "renders the form with error message" do
        post weather_index_path, params: { weather_service: { location: "invalid" } }

        expect(response.body).to include("Invalid zip code format")
      end
    end
  end
end
