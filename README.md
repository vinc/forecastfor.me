ForecastFor.me
==============


Features
--------

* Rails app with Sidekiq workers.
* Import data from the [Global Forecast System][1] model.
* Extract geolocalized forecasts from the data with [wgrib2][2].
* Serve custom weather bulletins on the Web with the [Geolocation API][3].
* Parse and respond to tweets mentioning @forecastfor with a time and a
  position or use metadata to make a guess.

[1]: http://www.nco.ncep.noaa.gov/pmb/products/gfs/
[2]: http://www.cpc.ncep.noaa.gov/products/wesley/wgrib2/
[3]: https://developer.mozilla.org/en-US/docs/Web/API/Geolocation/Using_geolocation


Copyright
---------

Copyright (C) 2014 Vincent Ollivier. See LICENSE for details.
