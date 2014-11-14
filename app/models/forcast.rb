class Forcast
  attr_accessor :longitude, :latitude

  def initialize(gfs, hour)
    @gfs = gfs
    @hour = hour
    @memoized_reads = {}
  end
 
  def set_location(longitude:, latitude:)
    @longitude = longitude
    @latitude = latitude
  end

  def precipitations
    (self.read('PRATE') * 3.hours).round(1)
  end

  def temperature
    (self.read('TMP') - 273.15).round
  end

  def wind
    u = self.read('UGRD')
    v = self.read('VGRD')
    Math.sqrt(u ** 2 + v ** 2).round
  end

  def cloud_cover
    self.read('TCDC').round
  end

  def as_json(options = {})
    {
      time: @gfs.time + @hour.hours,
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

  def read(name)
    @memoized_reads[name] ||= @gfs.record(
      name: name,
      forcast: @hour,
      longitude: @longitude,
      latitude: @latitude
    )
  end
end
