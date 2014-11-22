function success(pos) {
  var params = {
    latitude: pos.coords.latitude.toFixed(2),
    longitude: pos.coords.longitude.toFixed(2)
  };

  window.location = '/bulletin?' + $.param(params);
  console.log(window.location);
};

function error(err) {
  console.warn('ERROR(' + err.code + '): ' + err.message);
};

options = {
  enableHighAccuracy: true,
  maximumAge: 3600
};

if (window.location.pathname === '/') {
  navigator.geolocation.watchPosition(success, error, options);
}
