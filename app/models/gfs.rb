class GFS
  SERVER = 'http://www.ftp.ncep.noaa.gov/data/nccf/com/gfs/prod'
  RECORDS = [
    'PRES:surface',
    'PRATE:surface',
    'TMP:2 m above ground',
    'UGRD:10 m above ground',
    'VGRD:10 m above ground',
    'TCDC:entire atmosphere'
  ]

  def self.all
    Dir.foreach(Rails.root.join('tmp', 'gfs')).
      select { |dir| /\d{8}/ =~ dir }.
      map { |dir| GFS.new("#{dir}00") }
  end

  def self.last
    self.all.last
  end

  def initialize(yyyymmddcc = "#{Time.now.strftime('%Y%m%d')}00")
    @yyyymmdd = yyyymmddcc[0..7]
    @cc = yyyymmddcc[8..9]
  end

  def path
    "/runs/#{@yyyymmdd}"
  end

  def time
    Time.parse("#{@yyyymmdd}#{@cc} +0000")
  end

  def record(name:, forcast:, latitude:, longitude:)
    hh = '%02d' % forcast
    filename = "gfs.t#{@cc}z.pgrb2f#{hh}"

    Dir.chdir(Rails.root.join('tmp', 'gfs', @yyyymmdd)) do
      out = `wgrib2 #{filename} -s -lon #{longitude} #{latitude} -match '#{name}'`
      lines = out.split("\n")
      fields = lines.first.split(':')
      params = Hash[*fields.last.split(',').map { |s| s.split('=') }.flatten]
      
      params['val'].to_f
    end
  end

  def download!
    curl = 'curl -O -f -s -S'
    FileUtils.mkpath(Rails.root.join('tmp', 'gfs', @yyyymmdd))
    Dir.chdir(Rails.root.join('tmp', 'gfs', @yyyymmdd)) do
      (3..24).step(3).map do |forcast|
        hh = '%02d' % forcast
        filename = "gfs.t#{@cc}z.pgrb2f#{hh}"
        url = "#{GFS::SERVER}/gfs.#{@yyyymmdd}#{@cc}/#{filename}"

        Rails.logger.info("Downloading '#{url}.idx' ...")
        break unless system("#{curl} #{url}.idx")
        lines = IO.readlines("#{filename}.idx")
        n = lines.count
        ranges = lines.each_index.reduce([]) do |r, i|
          if GFS::RECORDS.any? { |record| lines[i].include?(record) }
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

        Rails.logger.info("Downloading '#{url}' ...")
        system("#{curl} -r #{ranges.join(',')} #{url}")
      end
    end
  end
end
