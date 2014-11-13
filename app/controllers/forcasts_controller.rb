class ForcastsController < ApplicationController
  expose(:gfs) do
    yyyymmddcc = params[:run_id] || "#{Time.now.strftime('%Y%m%d')}00"
    GFS.new(yyyymmddcc)
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

  def now
    self.forcast = forcasts[Time.now.utc.hour / 3]

    respond_with(forcast)
  end

  def today
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
