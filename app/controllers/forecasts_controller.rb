class ForecastsController < ApplicationController
  expose(:gfs) do
    params[:run_id] ? GFS.find(params[:run_id]) : GFS.last
  end

  expose(:longitude) do
    params[:longitude].try(:to_f) || request.location.longitude
  end

  expose(:latitude) do
    params[:latitude].try(:to_f) || request.location.latitude
  end

  expose(:forecasts) do
    gfs.forecasts(longitude: longitude, latitude: latitude)
  end

  expose(:forecast) do
    hour = Integer(params[:id] || '0')
    gfs.forecast(hour: hour, longitude: longitude, latitude: latitude)
  end

  def index
    respond_with(forecasts)
  end

  def show
    respond_with(forecast)
  end
end
