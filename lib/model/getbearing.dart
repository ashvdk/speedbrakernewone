import 'package:geolocator/geolocator.dart';

double getBearing(lat1, lng1, lat2, lng2){
  var bearing = Geolocator.bearingBetween(lat1, lng1, lat2, lng2);
  return bearing < 0.0 ? (bearing + 360.0) : bearing;
}