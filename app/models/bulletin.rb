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

  def weather
    cloud_cover = @forecasts.map(&:cloud_cover).sum / @forecasts.size

    weather =
      if cloud_cover > 75
        'Cloudy'
      elsif cloud_cover > 50
        'Mostly cloudy'
      elsif cloud_cover > 10
        'Partly cloudy'
      else
        'Clear'
      end

    precipitations = @forecasts.map(&:precipitations).sum
    unit = 'mm'

    if precipitations > 1
      "#{weather} with #{'%.1f' % precipitations} #{unit} of rain."
    else
      "#{weather}."
    end
  end

  def temperature
    forecasts = @forecasts.sort_by { |forecast| forecast.temperature }
    I18n.t('bulletin_temperature',
      unit: '°C',
      min_value: forecasts.first.temperature,
      min_time: forecasts.first.time.strftime('%H%M'),
      max_value: forecasts.last.temperature,
      max_time: forecasts.last.time.strftime('%H%M')
    )
  end

  def wind
    forecasts = @forecasts.sort_by { |forecast| forecast.wind }
    I18n.t('bulletin_wind',
      unit: 'm/s',
      min_value: forecasts.first.wind,
      min_time: forecasts.first.time.strftime('%H%M'),
      max_value: forecasts.last.wind,
      max_time: forecasts.last.time.strftime('%H%M')
    )
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
