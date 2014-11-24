class Bulletin
  attr_accessor :date, :longitude, :latitude

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
  end

  def forecasts
    @forecasts ||= (1..24).map do |i|
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
    cloud_cover = forecasts.map(&:cloud_cover).sum / forecasts.size

    weather =
      if cloud_cover > 75
        I18n.t('bulletin.weather_75')
      elsif cloud_cover > 50
        I18n.t('bulletin.weather_50')
      elsif cloud_cover > 10
        I18n.t('bulletin.weather_10')
      else
        I18n.t('bulletin.weather_00')
      end

    precipitations = forecasts.map(&:precipitations).sum

    if precipitations > 0.1
      str = I18n.t('bulletin.precipitation',
        unit: 'mm',
        value: '%.1f' % precipitations
      )
      "#{weather} #{str}."
    else
      "#{weather}."
    end
  end

  def temperature
    sorted_forecasts = forecasts.sort_by { |forecast| forecast.temperature }
    min = sorted_forecasts.first
    max = sorted_forecasts.last
    I18n.t('bulletin.temperature',
      unit: '°C',
      min_value: min.temperature,
      min_time: I18n.l(min.time.in_time_zone, format: :shortest),
      max_value: max.temperature,
      max_time: I18n.l(max.time.in_time_zone, format: :shortest)
    )
  end

  def wind
    sorted_forecasts = forecasts.sort_by { |forecast| forecast.wind }
    min = sorted_forecasts.first
    max = sorted_forecasts.last
    I18n.t('bulletin.wind',
      unit: 'm/s',
      min_value: min.wind,
      min_time: I18n.l(min.time.in_time_zone, format: :shortest),
      max_value: max.wind,
      max_time: I18n.l(max.time.in_time_zone, format: :shortest)
    )
  end

  def as_json(options = {})
    {
      date: @date,
      longitude: forecasts.first.longitude,
      latitude: forecasts.first.latitude,
      precipitations: forecasts.map(&:precipitations).sum.round(1),
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
end
