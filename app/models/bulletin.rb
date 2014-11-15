class Bulletin
  attr_accessor :longitude, :latitude

  def initialize(gfs:, longitude:, latitude:)
    @gfs = gfs
    @longitude = longitude
    @latitude = latitude
    @forecasts = (3..24).step(3).map do |hour|
      Forecast.new(
        gfs: gfs,
        hour: hour,
        longitude: longitude,
        latitude: latitude
      )
    end
  end

  def as_json(options = {})
    {
      date: @gfs.time.to_date,
      longitude: @forecasts.first.longitude,
      latitude: @forecasts.first.latitude,
      precipitations: @forecasts.map(&:precipitations).sum,
      precipitations_unit: 'mm',
      temperature_max: @forecasts.map(&:temperature).max,
      temperature_min: @forecasts.map(&:temperature).min,
      temperature_unit: '°C',
      wind_max: @forecasts.map(&:wind).max,
      wind_min: @forecasts.map(&:wind).min,
      wind_unit: 'm/s',
      cloud_cover: @forecasts.map(&:cloud_cover).sum / @forecasts.size,
      cloud_cover_unit: '%'
    }
  end
end
