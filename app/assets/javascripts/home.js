function locale() {
  return localStorage.locale || window.navigator.language.split('-')[0] || 'en';
}

function units() {
  return localStorage.units || 'metric';
}

function city() {
  return localStorage.city || '';
}

function poll(path, callback) {
  console.log('wait ' + path);

  $.get(path, function(data, textStatus, jqXHR) {
    if (jqXHR.status === 200) {
      console.log('goto ' + path);
      callback();
    } else {
      setTimeout(function() { poll(path, callback) }, 2000);
    }
  });
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

function redirectToBulletin(params) {
  var path = '/bulletin?' + $.param(params);

  poll(path, function() {
    Turbolinks.visit(path);
  });
}

$(document).on('ready page:load', function() {
  var params = {
    date: querystring(window.location.search).date || 'today',
  };

  $('#settings form [name=city]').val(city());

  if (window.location.pathname === '/') {
    params.locale = locale();
    params.units = units();

    if (city()) {
      params.city = city();
      redirectToBulletin(params);
    } else {
      console.log('waiting for geolocation');
      navigator.geolocation.getCurrentPosition(function(pos) {
        console.log('geolocation found');
        params.latitude = pos.coords.latitude.toFixed(2);
        params.longitude = pos.coords.longitude.toFixed(2);
        redirectToBulletin(params);
      });
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
    window.location = '/';
  });
});
