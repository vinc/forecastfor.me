class Bulletin
  attr_accessor :date, :longitude, :latitude, :forecasts

  # TODO: move method to GFS class
  # There is a GFS run every 6 hours starting at midnight and it takes
  # approximately 3 to 5 hours before a run is available to download.
  def self.run_time(time)
    time = [time, Time.now].min.utc

    midnight = time.at_beginning_of_day

    hours_since_midnight = ((time - midnight) / 3600).round
    hours_to_wait_for_gfs = 5
    hours = hours_since_midnight - hours_to_wait_for_gfs

    midnight + 6 * (hours / 6).hours
  end

  # TODO: move method to Forecast class
  # A GFS run contains one forecast for every 3 hours.
  def self.forecast_hours(time)
    3 * (((time - self.run_time(time)) / 3600).round / 3)
  end

  def initialize(date = Date.today, longitude:, latitude:)
    @date = date
    @longitude = longitude
    @latitude = latitude

    @forecasts = (1..24).map do |i|
      t = date.at_beginning_of_day.utc + i.hours

      time = Bulletin.run_time(t)
      hour = Bulletin.forecast_hours(t)

      gfs = GFS.find_or_create(time.strftime('%Y%m%d%H'))
      gfs.forecast(hour: hour, longitude: longitude, latitude: latitude)
    end.uniq # FIXME: extrapolate for every hour
  end

  def location
    address = Geocoder.search([@latitude, @longitude]).first
    %w(city country).map { |c| address.send(c) }.join(', ')
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

    if precipitations > 0.1
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
      min_time: I18n.l(forecasts.first.time.in_time_zone, format: :shortest),
      max_value: forecasts.last.temperature,
      max_time: I18n.l(forecasts.last.time.in_time_zone, format: :shortest)
    )
  end

  def wind
    forecasts = @forecasts.sort_by { |forecast| forecast.wind }
    I18n.t('bulletin_wind',
      unit: 'm/s',
      min_value: forecasts.first.wind,
      min_time: I18n.l(forecasts.first.time.in_time_zone, format: :shortest),
      max_value: forecasts.last.wind,
      max_time: I18n.l(forecasts.last.time.in_time_zone, format: :shortest)
    )
  end

  def as_json(options = {})
    {
      date: @date,
      longitude: @forecasts.first.longitude,
      latitude: @forecasts.first.latitude,
      precipitations: @forecasts.map(&:precipitations).sum.round(1),
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
