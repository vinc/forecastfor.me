var settings = {
  locale: window.navigator.language.split('-')[0] || 'en',
  units: 'metric',
  city: ''
};

function restoreSettings() {
  for (k in settings) {
    settings[k] = localStorage[k] || settings[k];
  }
}

function querystring(str) {
  var strings = str.substring(1).split('&');
  var params = {};
  var i, n;

  for (i = 0, n = strings.length; i < n; i++) {
    var kv = strings[i].split('=');

    params[kv[0]] = kv[1];
  }
  return params;
}

$(document).on('ready page:load', function() {
  var params = {
    date: querystring(window.location.search).date || 'today',
  };

  restoreSettings();
  $('#settings form [name=city]').val(settings.city);

  if (window.location.pathname === '/') {
    params.locale = settings.locale;
    params.units = settings.units;

    if (settings.city) {
      params.city = settings.city;
      path = '/bulletin?' + $.param(params);
      Turbolinks.visit('/bulletin?' + $.param(params));
    } else {
      console.log('waiting for geolocation');
      navigator.geolocation.getCurrentPosition(function(pos) {
        console.log('geolocation found');
        params.latitude = pos.coords.latitude.toFixed(2);
        params.longitude = pos.coords.longitude.toFixed(2);
      });
      Turbolinks.visit('/bulletin?' + $.param(params));
    }
  }

  $('#settings form').submit(function(e) {
    e.preventDefault();
    params.latitude = $('#settings form [name=latitude]').val();
    params.longitude = $('#settings form [name=longitude]').val();
    params.city = $('#settings form [name=city]').val();
    params.locale = $('#settings form [name=locale]').val();
    params.units = $('#settings form [name=units]').val();
    if (params.city) {
      localStorage.city = params.city;
      delete params.latitude;
      delete params.longitude;
    } else {
      delete localStorage.city;
      delete params.city;
    }
    localStorage.locale = params.locale;
    localStorage.units = params.units;
    Turbolinks.visit('/');
  });
});
