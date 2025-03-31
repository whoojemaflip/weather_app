# Weather App

A Ruby on Rails application that provides same-day weather forecasts for any given US zipcode. The app retrieves current temperature and forecast data, with caching implemented for improved performance.

## Features

- Address-based weather lookup
- Current temperature display
- Extended forecast information (for the current day)
- 30-minute caching for zip code-based requests
- Cache status indicator
- Comprehensive test suite
- Code quality checks with RuboCop

## Prerequisites

- Ruby 3.3.1
- Rails 8.0.2
- WeatherAPI.com API key

## Setup

1. Clone the repository:
```bash
git clone git@github.com:whoojemaflip/weather_app.git
cd weather_app
```

2. Install dependencies:
```bash
bundle install
```

3. Configure WeatherAPI.com API key:
   - Sign up for a free API key at [WeatherAPI.com](https://www.weatherapi.com/)
   - Copy the example environment file:
   ```bash
   cp example.env .env
   ```
   - Add your API key to the `.env` file:
   ```
   WEATHER_API_KEY=your_api_key_here
   ```

## Running the Application

Start the Rails server:
```bash
rails server
```

Visit `http://localhost:3000` in your browser.

## Development Commands

### Running Tests
```bash
# Run all tests
bundle exec rspec
```

### Code Quality Checks
```bash
# Run RuboCop
bundle exec rubocop
```


## Caching

The application implements a 30-minute cache for weather data based on zip codes. When viewing weather information, you'll see an indicator if the data is being served from the cache.


