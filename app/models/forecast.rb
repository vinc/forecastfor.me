class Forecast
  attr_accessor :longitude, :latitude

  def initialize(gfs:, hour:, longitude:, latitude:)
    @gfs = gfs
    @hour = hour
    @longitude = longitude
    @latitude = latitude
    @memoized_reads = {}
  end

  def hash
    [time, longitude, latitude].hash
  end

  def eql?(other)
    self.hash == other.hash
  end

  alias == eql?

  def time
    @gfs.time + @hour.hours
  end

  def precipitations
    (self.read(:prate) * 1.hour).round(1)
  end

  def temperature
    (self.read(:tmp) - 273.15).round
  end

  def wind
    u = self.read(:ugrd)
    v = self.read(:vgrd)
    Math.sqrt(u ** 2 + v ** 2).round
  end

  def cloud_cover
    self.read(:tcdc).round
  end

  def as_json(options = {})
    {
      time: self.time,
      longitude: @longitude,
      latitude: @latitude,
      precipitations: self.precipitations,
      precipitations_unit: 'mm',
      temperature: self.temperature,
      temperature_unit: '°C',
      wind: self.wind,
      wind_unit: 'm/s',
      cloud_cover: self.cloud_cover,
      cloud_cover_unit: '%'
    }
  end

  protected

  def read(field)
    @memoized_reads[field] ||= @gfs.read(
      field,
      hour: @hour,
      longitude: @longitude,
      latitude: @latitude
    )
  end
end
