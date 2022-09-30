import 'package:flutter/material.dart';
import 'package:testing_isolate/allspeedbrakers.dart';
import 'package:geolocator/geolocator.dart';
import 'package:testing_isolate/waterripple.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Position _locationData;
  bool gotlocation = false;
  @override
  void initState() {
    _determinePosition();
  }
  void _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    var location = await Geolocator.getCurrentPosition();

    setState((){
      _locationData = location;
      gotlocation = true;
    });
  }
  @override
  Widget build(BuildContext context) {
    // return Scaffold(
    //   body: Center(
    //       child: Container(height: 200, width: 200, child: WaterRipple())),
    // );
    return gotlocation ? NewSpeedBraker() : Container(child: Text('You need to provide location permission'),);
  }
}
