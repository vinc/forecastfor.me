class ForcastsController < ApplicationController
  expose(:gfs) do
    params[:run_id] ? GFS.new(params[:run_id]) : GFS.last
  end

  expose(:forcasts) do
    longitude = Float(params[:longitude] || '2.37')
    latitude = Float(params[:latitude] || '48.87')

    (3..24).step(3).map do |id|
      forcast = Forcast.new(gfs, id)
      forcast.set_location(longitude: longitude, latitude: latitude)
      forcast
    end
  end

  expose(:forcast) do
    forcasts[Integer(params[:id] || '0') / 3]
  end

  def index
    respond_with(forcasts)
  end

  def show
    respond_with(forcast)
  end

  def summary
    respond_with({
      date: gfs.time.to_date,
      longitude: forcasts.first.longitude,
      latitude: forcasts.first.latitude,
      precipitations: forcasts.map(&:precipitations).sum,
      precipitations_unit: 'mm',
      temperature_max: forcasts.map(&:temperature).max,
      temperature_min: forcasts.map(&:temperature).min,
      temperature_unit: '°C',
      wind: forcasts.map(&:wind).sum / forcasts.size,
      wind_unit: 'km/h',
      cloud_cover: forcasts.map(&:cloud_cover).sum / forcasts.size,
      cloud_cover_unit: '%'
    })
  end
end
