class ForecastsController < ApplicationController
  expose(:gfs) do
    params[:run_id] ? GFS.new(params[:run_id]) : GFS.last
  end

  expose(:longitude) do
    params[:longitude].try(:to_f) || request.location.longitude
  end

  expose(:latitude) do
    params[:latitude].try(:to_f) || request.location.latitude
  end

  expose(:forecasts) do
    (3..24).step(3).map do |hour|
      Forecast.new(
        gfs: gfs,
        hour: hour,
        longitude: longitude,
        latitude: latitude
      )
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
