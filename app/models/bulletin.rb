require 'descriptive_statistics'

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
    end
  end

  def location
    Geocoder.search([@latitude, @longitude]).first
  end

  def night
    period(0..5)
  end

  def morning
    period(6..11)
  end

  def afternoon
    period(12..17)
  end

  def evening
    period(18..23)
  end

  def day
    period(6..22)
  end

  def period(range = 0..23)
    time =
      case range
      when 0..5
        I18n.t('bulletin.time.night')
      when 6..11
        I18n.t('bulletin.time.morning')
      when 12..17
        I18n.t('bulletin.time.afternoon')
      when 18..23
        I18n.t('bulletin.time.evening')
      else
        I18n.t('bulletin.time.day')
      end

    values = {
      sky: sky(range),
      rain: rain(range),
      wind: wind(range),
      time: time
    }
    weather =
      if forecasts[range].map(&:precipitations).median > 0.0
        if forecasts[range].map(&:wind).median >= 1.5
          I18n.t('bulletin.weather.sky_rain_wind', values)
        else
          I18n.t('bulletin.weather.sky_rain', values)
        end
      else
        if forecasts[range].map(&:wind).median >= 1.5
          I18n.t('bulletin.weather.sky_wind', values)
        else
          I18n.t('bulletin.weather.sky', values)
        end
      end

    [weather, temperature(range)].map do |str|
      str[0] = str[0].capitalize
      "#{str}."
    end.join(' ')
  end

  def sky(range = 0..23)
    case forecasts[range].map(&:cloud_cover).median
    when 0...10
      I18n.t('bulletin.sky.clear')
    when 10...40
      I18n.t('bulletin.sky.mostly_clear')
    when 40...70
      I18n.t('bulletin.sky.partly_cloudy')
    when 70...90
      I18n.t('bulletin.sky.mostly_cloudy')
    else
      I18n.t('bulletin.sky.cloudy')
    end
  end

  def rain(range = 0..23)
    case forecasts[range].map(&:precipitations).median
    when 0.0...2.5
      I18n.t('bulletin.rain.light')
    when 2.5...10.0
      I18n.t('bulletin.rain.moderate')
    when 10.0...50.0
      I18n.t('bulletin.rain.heavy')
    else
      I18n.t('bulletin.rain.violent')
    end
  end

  def wind(range = 0..23)
    case forecasts[range].map(&:wind).median
    when 0.0...0.3
      I18n.t('bulletin.wind.calm')
    when 0.3...1.5
      I18n.t('bulletin.wind.light_air')
    when 1.5...3.3
      I18n.t('bulletin.wind.light_breeze')
    when 3.3...5.4
      I18n.t('bulletin.wind.gentle_breeze')
    when 5.4...7.9
      I18n.t('bulletin.wind.moderate_breeze')
    when 7.9...10.7
      I18n.t('bulletin.wind.fresh_breeze')
    when 10.7...13.8
      I18n.t('bulletin.wind.strong_breeze')
    when 13.8...17.1
      I18n.t('bulletin.wind.moderate_gale')
    when 17.1...20.7
      I18n.t('bulletin.wind.fresh_gale')
    when 20.7...24.4
      I18n.t('bulletin.wind.strong_gale')
    when 24.4...28.4
      I18n.t('bulletin.wind.storm')
    when 28.4...32.6
      I18n.t('bulletin.wind.violent_storm')
    else
      I18n.t('bulletin.wind.huricane')
    end
  end

  def temperature(range = 0..23)
    temperatures = forecasts[range].map(&:temperature)
    values = {
      unit: '°C',
      median: temperatures.median.round,
      min: temperatures.min,
      max: temperatures.max
    }
    if temperatures.standard_deviation < 2.0
      I18n.t('bulletin.temperature.around', values)
    else
      I18n.t('bulletin.temperature.between', values)
    end
  end

  def statistics(quantity)
    forecasts.map(&quantity).
      descriptive_statistics.
      slice(:min, :max, :q1, :q2, :q3)
  end

  def as_json(options = {})
    {
      date: @date,
      location: %w(city country).map { |c| location.send(c) }.join(', '),
      longitude: forecasts.first.longitude,
      latitude: forecasts.first.latitude,
      precipitations_hourly: forecasts.map(&:precipitations),
      precipitations_stats: statistics(:precipitations),
      precipitations_unit: 'mm',
      temperature_hourly: forecasts.map(&:temperature),
      temperature_stats: statistics(:temperature),
      temperature_unit: '°C',
      wind_hourly: forecasts.map(&:wind),
      wind_stats: statistics(:wind),
      wind_unit: 'm/s',
      cloud_cover_hourly: forecasts.map(&:cloud_cover),
      cloud_cover_stats: statistics(:cloud_cover),
      cloud_cover_unit: '%'
    }
  end
end
