function locale() {
  return localStorage.locale || window.navigator.language.split('-')[0] || 'en';
}

function units() {
  return localStorage.units || 'metric';
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

$(document).on('ready page:load', function() {
  if (window.location.pathname === '/') {
    console.log('waiting for geolocation');

    navigator.geolocation.getCurrentPosition(function(pos) {
      var params = {
        latitude: pos.coords.latitude.toFixed(2),
        longitude: pos.coords.longitude.toFixed(2),
        locale: locale(),
        units: units()
      };

      var path = '/bulletin?' + $.param(params);

      console.log('geolocation found');
      poll(path, function() {
        Turbolinks.visit(path);
      });
    });
  }

  $('#settings form').submit(function(e) {
    var params = {
      latitude: $('#settings form [name=latitude]').val(),
      longitude: $('#settings form [name=longitude]').val(),
      locale: $('#settings form [name=locale]').val(),
      units: $('#settings form [name=units]').val()
    }
    var path = '/bulletin?' + $.param(params);

    localStorage.locale = params.locale;
    localStorage.units = params.units;
    e.preventDefault();

    //poll(path, function() {
      Turbolinks.visit(path);
    //});
  });
});
