class GFS
  SERVER = 'http://www.ftp.ncep.noaa.gov/data/nccf/com/gfs/prod'
  RECORDS = {
    prate: 'PRATE:surface',
    tmp:   'TMP:2 m above ground',
    ugrd:  'UGRD:10 m above ground',
    vgrd:  'VGRD:10 m above ground',
    tcdc:  'TCDC:entire atmosphere'
  }
  FORECAST_HOURS = (3..114).step(3)

  def self.all
    Dir.foreach(Rails.root.join('tmp', 'gfs')).
      select { |dir| /\d{8}/ =~ dir }.
      sort_by { |dir| dir.to_i }.
      map { |dir| GFS.new(dir) }
  end

  def self.last
    self.all.last
  end

  def self.find(yyyymmddcc)
    if Dir.exist?(Rails.root.join('tmp', 'gfs', yyyymmddcc))
      self.new(yyyymmddcc)
    else
      nil
    end
  end

  def self.create(yyyymmddcc = "#{Time.now.strftime('%Y%m%d')}00")
    gfs = self.new(yyyymmddcc)
    gfs.download!
    gfs
  end

  def self.find_or_create(yyyymmddcc)
    self.find(yyyymmddcc) || self.create(yyyymmddcc)
  end

  def initialize(yyyymmddcc = "#{Time.now.strftime('%Y%m%d')}00")
    @yyyymmdd = yyyymmddcc[0..7]
    @cc = yyyymmddcc[8..9]
  end

  def path
    "/runs/#{@yyyymmdd}#{@cc}"
  end

  def time
    Time.parse("#{@yyyymmdd}#{@cc} +0000")
  end

  def read(field, hour: 3, latitude:, longitude:)
    key = [@yyyymmdd + @cc, field, hour, latitude, longitude].join(':')
    unless Redis.current.exists(key)
      wgrib2 = Rails.root.join('bin', 'wgrib2')
      record = GFS::RECORDS[field]

      filename = "gfs.t#{@cc}z.pgrb2f#{'%02d' % hour}"
      pathname = Rails.root.join('tmp', 'gfs', @yyyymmdd + @cc)
      path = Rails.root.join(pathname, filename)
      raise "'#{path}' not found" unless File.exists?(path)

      out = `#{wgrib2} #{path} -lon #{longitude} #{latitude} -match '#{record}'`
      lines = out.split("\n")
      fields = lines.first.split(':')
      params = Hash[*fields.last.split(',').map { |s| s.split('=') }.flatten]

      ttl = 1.hour
      val = params['val']
      Redis.current.setex(key, ttl, val)
    end
    Redis.current.get(key).to_f
  end

  def download!
    curl = 'curl -f -s -S'

    pathname = Rails.root.join('tmp', 'gfs', @yyyymmdd + @cc)
    FileUtils.mkpath(pathname)

    GFS::FORECAST_HOURS.map do |hour|
      filename = "gfs.t#{@cc}z.pgrb2f#{'%02d' % hour}"
      url = "#{GFS::SERVER}/gfs.#{@yyyymmdd}#{@cc}/#{filename}"
      path = Rails.root.join(pathname, filename)

      Rails.logger.info("Downloading '#{url}.idx' ...")
      break unless system("#{curl} -o #{path}.idx #{url}.idx")

      lines = IO.readlines("#{path}.idx")
      n = lines.count
      ranges = lines.each_index.reduce([]) do |r, i|
        if GFS::RECORDS.values.any? { |record| lines[i].include?(record) }
          first = lines[i].split(':')[1].to_i
          last = ''

          j = i
          while (j += 1) < n
            last = lines[j].split(':')[1].to_i - 1
            break if last != first - 1
          end

          r << "#{first}-#{last}" # cURL syntax for a range
        else
          r
        end
      end
      system("rm #{path}.idx")

      Rails.logger.info("Downloading '#{url}' ...")
      system("#{curl} -r #{ranges.join(',')} -o #{path} #{url}")
    end
  end

  def forecast(hour:, longitude:, latitude:)
    Forecast.new(
      gfs: self,
      hour: hour,
      longitude: longitude,
      latitude: latitude
    )
  end

  def forecasts(longitude:, latitude:)
    GFS::FORECAST_HOURS.map do |hour|
      forecast(hour: hour, longitude: longitude, latitude: latitude)
    end
  end
end
