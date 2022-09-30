import 'dart:math';

const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

class Geohash {

  /**
   * Encodes latitude/longitude to geohash, either to specified precision or to automatically
   * evaluated precision.
   *
   * @param   {number} lat - Latitude in degrees.
   * @param   {number} lon - Longitude in degrees.
   * @param   {number} [precision] - Number of characters in resulting geohash.
   * @returns {string} Geohash of supplied latitude/longitude.
   * @throws  Invalid geohash.
   *
   * @example
   *     const geohash = Geohash.encode(52.205, 0.119, 7); // => 'u120fxw'
   */
  static encode(lat, lon) {
    int precision = 9;

    //if (isNaN(lat)  || isNaN(lon) || isNaN(precision)) throw new Error('Invalid geohash');

    var idx = 0; // index into base32 map
    var bit = 0; // each char holds 5 bits
    var evenBit = true;
    var geohash = '';

    double latMin =  -90, latMax =  90;
    double lonMin = -180, lonMax = 180;

    while (geohash.length < precision) {
      if (evenBit) {
        // bisect E-W longitude
        var lonMid = (lonMin + lonMax) / 2;
        if (lon >= lonMid) {
          idx = idx*2 + 1;
          lonMin = lonMid;
        } else {
          idx = idx*2;
          lonMax = lonMid;
        }
      } else {
        // bisect N-S latitude
        var latMid = (latMin + latMax) / 2;
        if (lat >= latMid) {
          idx = idx*2 + 1;
          latMin = latMid;
        } else {
          idx = idx*2;
          latMax = latMid;
        }
      }
      evenBit = !evenBit;

      if (++bit == 5) {
        // 5 bits gives us a character: append it and start over
        geohash += base32[idx];
        bit = 0;
        idx = 0;
      }
    }

    return geohash;
  }


  /**
   * Determines adjacent cell in given direction.
   *
   * @param   geohash - Cell to which adjacent cell is required.
   * @param   direction - Direction from geohash (N/S/E/W).
   * @returns {string} Geocode of adjacent cell.
   * @throws  Invalid geohash.
   */
  static adjacent(geohash, direction) {
    // based on github.com/davetroy/geohash-js

    geohash = geohash.toLowerCase();
    direction = direction.toLowerCase();

    // if (geohash.length == 0) throw new Error('Invalid geohash');
    // if ('nsew'.indexOf(direction) == -1) throw new Error('Invalid direction');

    //const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
    Map neighbour = {
      'n': [ 'p0r21436x8zb9dcf5h7kjnmqesgutwvy', 'bc01fg45238967deuvhjyznpkmstqrwx' ],
      's': [ '14365h7k9dcfesgujnmqp0r2twvyx8zb', '238967debc01fg45kmstqrwxuvhjyznp' ],
      'e': [ 'bc01fg45238967deuvhjyznpkmstqrwx', 'p0r21436x8zb9dcf5h7kjnmqesgutwvy' ],
      'w': [ '238967debc01fg45kmstqrwxuvhjyznp', '14365h7k9dcfesgujnmqp0r2twvyx8zb' ],
    };
    Map border = {
      'n': [ 'prxz', 'bcfguvyz' ],
      's': [ '028b', '0145hjnp' ],
      'e': [ 'bcfguvyz', 'prxz' ],
      'w': [ '0145hjnp', '028b' ],
    };

    var lastCh = geohash.substring(geohash.length - 1);    // last character of hash
    var parent = geohash.substring(0, geohash.length - 1); // hash without last character

    int type = geohash.length % 2;

    // check for edge-cases which don't share common prefix
    if (border[direction][type].indexOf(lastCh) != -1 && parent != '') {
      parent = Geohash.adjacent(parent, direction);
    }

    // append letter for direction to parent
    return parent + base32[neighbour[direction][type].indexOf(lastCh)];
  }

  static bounds(geohash) {
    //if (geohash.length == 0) throw new Error('Invalid geohash');

    geohash = geohash.toLowerCase();

    var evenBit = true;
    double latMin =  -90, latMax =  90;
    double lonMin = -180, lonMax = 180;

    for (var i=0; i<geohash.length; i++) {
      var chr = geohash[i];
      var idx = base32.indexOf(chr);
      //if (idx == -1) throw new Error('Invalid geohash');

      for (var n=4; n>=0; n--) {
        var bitN = idx >> n & 1;
        if (evenBit) {
          // longitude
          var lonMid = (lonMin+lonMax) / 2;
          if (bitN == 1) {
            lonMin = lonMid;
          } else {
            lonMax = lonMid;
          }
        } else {
          // latitude
          var latMid = (latMin+latMax) / 2;
          if (bitN == 1) {
            latMin = latMid;
          } else {
            latMax = latMid;
          }
        }
        evenBit = !evenBit;
      }
    }

    var bounds = {
      'sw': { 'lat': latMin, 'lon': lonMin },
      'ne': { 'lat': latMax, 'lon': lonMax },
    };

    return bounds;
  }
  /**
   * Returns all 8 adjacent cells to specified geohash.
   *
   * @param   {string} geohash - Geohash neighbours are required of.
   * @returns {{n,ne,e,se,s,sw,w,nw: string}}
   * @throws  Invalid geohash.
   */
  static neighbours(geohash) {
    return {
      'n':  Geohash.adjacent(geohash, 'n'),
      'ne': Geohash.adjacent(Geohash.adjacent(geohash, 'n'), 'e'),
      'e':  Geohash.adjacent(geohash, 'e'),
      'se': Geohash.adjacent(Geohash.adjacent(geohash, 's'), 'e'),
      's':  Geohash.adjacent(geohash, 's'),
      'sw': Geohash.adjacent(Geohash.adjacent(geohash, 's'), 'w'),
      'w':  Geohash.adjacent(geohash, 'w'),
      'nw': Geohash.adjacent(Geohash.adjacent(geohash, 'n'), 'w'),
    };
  }
  /**
   * Decode geohash to latitude/longitude (location is approximate centre of geohash cell,
   *     to reasonable precision).
   *
   * @param   {string} geohash - Geohash string to be converted to latitude/longitude.
   * @returns {{lat:number, lon:number}} (Center of) geohashed location.
   * @throws  Invalid geohash.
   *
   * @example
   *     const latlon = Geohash.decode('u120fxw'); // => { lat: 52.205, lon: 0.1188 }
   */
  static decode(geohash) {

    var bounds = Geohash.bounds(geohash); // <-- the hard work
    // now just determine the centre of the cell...

    double latMin = bounds['sw']['lat'], lonMin = bounds['sw']['lon'];
    double latMax = bounds['ne']['lat'], lonMax = bounds['ne']['lon'];

    // cell centre
    var lat = (latMin + latMax)/2;
    var lon = (lonMin + lonMax)/2;

    // round to close to centre without excessive precision: ⌊2-log10(Δ°)⌋ decimal places
    lat = double.parse(lat.toStringAsFixed((2 - log(latMax-latMin)/ln10).floor()));
    lon = double.parse(lon.toStringAsFixed((2 - log(lonMax-lonMin)/ln10).floor()));

    return { 'lat': lat, 'lon': lon };
  }
}