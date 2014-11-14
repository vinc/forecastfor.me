class ForecastsController < ApplicationController
  expose(:gfs) do
    params[:run_id] ? GFS.new(params[:run_id]) : GFS.last
  end

  expose(:forecasts) do
    longitude = Float(params[:longitude] || '2.37')
    latitude = Float(params[:latitude] || '48.87')

    (3..24).step(3).map do |id|
      forecast = Forecast.new(gfs, id)
      forecast.set_location(longitude: longitude, latitude: latitude)
      forecast
    end
  end

  expose(:forecast) do
    forecasts[Integer(params[:id] || '0') / 3]
  end

  expose(:forecast_summary) do
    {
      date: gfs.time.to_date,
      longitude: forecasts.first.longitude,
      latitude: forecasts.first.latitude,
      precipitations: forecasts.map(&:precipitations).sum,
      precipitations_unit: 'mm',
      temperature_max: forecasts.map(&:temperature).max,
      temperature_min: forecasts.map(&:temperature).min,
      temperature_unit: '°C',
      wind_max: forecasts.map(&:wind).max,
      wind_min: forecasts.map(&:wind).min,
      wind_unit: 'm/s',
      cloud_cover: forecasts.map(&:cloud_cover).sum / forecasts.size,
      cloud_cover_unit: '%'
    }
  end

  def index
    respond_with(forecasts)
  end

  def show
    respond_with(forecast)
  end

  def summary
    respond_with(forecast_summary)
  end
end
