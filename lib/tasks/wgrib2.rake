namespace :wgrib2 do
  desc 'Compile wgrib2'
  task compile: :environment do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        sh 'curl -Os ftp://ftp.cpc.ncep.noaa.gov/wd51we/wgrib2/wgrib2.tgz'
        sh 'tar -xzvf wgrib2.tgz'
        Dir.chdir('grib2') do
          sh 'CC=gcc FC=gfortran make'
          mv 'wgrib2/wgrib2', Rails.root.join('bin')
        end
      end
    end
  end
end
