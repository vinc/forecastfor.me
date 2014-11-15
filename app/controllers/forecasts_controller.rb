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

  def index
    respond_with(forecasts)
  end

  def show
    respond_with(forecast)
  end
end
