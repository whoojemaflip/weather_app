class WeatherController < ApplicationController
  def new
    @forecast = WeatherService.new
  end

  def create
    response = WeatherService.call(location)

    if response.success?
      @forecast = response.forecast
      @from_cache = response.from_cache
      render :show
    else
      @forecast = WeatherService.new(location:)
      flash.now[:error] = response.error_message
      render :new, status: :unprocessable_entity
    end
  end

  private

  def location
    params.dig(:weather_service, :location)
  end
end
