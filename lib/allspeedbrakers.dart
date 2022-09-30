import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:testing_isolate/waterripple.dart';
import 'dart:math';

import 'newroad.dart';

class NewSpeedBraker extends StatefulWidget {
  const NewSpeedBraker({Key? key}) : super(key: key);

  @override
  State<NewSpeedBraker> createState() => _NewSpeedBrakerState();
}

class _NewSpeedBrakerState extends State<NewSpeedBraker> {
  var db = FirebaseFirestore.instance;
  final Completer<GoogleMapController> _controller = Completer();
  Set<Circle> _circle = {};
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  int precision = 9;
  late Position myLocation;
  bool gotlocation = false;
  bool showAlert = false;
  var ourCellName = "";
  int heading = 0;
  String direction = "";
  String speed = "0";
  final LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
      timeLimit: Duration(seconds: 1)
  );
  //google maps settings start
  static const LatLng _center = LatLng(12.8924552, 77.529757);
  static const CameraPosition _kGooglePlex = CameraPosition(
    target: _center,
    zoom: 18,
    //   tilt: 50.0,
    // bearing: 45.0,
  );
  LatLng _lastMapPosition = _center;
  void _onCameraMove(CameraPosition position) async {
    // final GoogleMapController controller = await _controller.future;
    // controller.animateCamera(
    //   CameraUpdate.newCameraPosition(
    //     CameraPosition(
    //       target: LatLng(position.target.latitude, position.target.longitude),
    //       tilt: 10.0,
    //     ),
    //   ),
    // );
    _lastMapPosition = position.target;
  }
  //google map setting end

  @override
  void initState() {
    _determinePosition();
    drawRoads();
    //getBoxData();
  }
  void drawRoads() async {
    Set<Polyline> tempPolylines = {};
    final temproads = await db.collection("roads").get();
    var roads = temproads.docs.toList();
    await Future.forEach(roads, (DocumentSnapshot element) async {
      if(element != null){
        final road = element.data() as Map<String, dynamic>;
        Map<String, dynamic> speedbrakersasmap = {};
        List<LatLng> listofspeedbrakers = [];
        print("printing road details----------------");
        print("${element.id}");
        print("${road["roadName"]}");
        var tempSpeedBrakers = await db.collection("speedbrakersinroad").where("roadid", isEqualTo: element.id).get();
        var speedbrakers = tempSpeedBrakers.docs.toList();
        speedbrakers.forEach((element) {
          final speedbraker = element.data() as Map<String, dynamic>;
          speedbrakersasmap[speedbraker["cellName"]] = speedbraker;
        });
        var ourRoad = road["head"];
        while(ourRoad != ""){
          var speedbrakerCoordinate = speedbrakersasmap[ourRoad];
          listofspeedbrakers.add(LatLng(speedbrakerCoordinate["coordinates"][0], speedbrakerCoordinate["coordinates"][1]));
          ourRoad = speedbrakerCoordinate["nextnode"]["cellname"];
        }
        print(listofspeedbrakers);
        tempPolylines.add(
            Polyline(
                polylineId: PolylineId(element.id),
                visible: true,
                //latlng is List<LatLng>
                points: listofspeedbrakers,
                color: Colors.blue,
                consumeTapEvents: true,
                onTap: (){
                  Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => NewRoad(roadName: element.id)));
                }
            )
        );
      }

    });
    print("poly lines----------");
    print(tempPolylines);
    setState((){
      _polylines = {...tempPolylines};
    });
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
    final GoogleMapController controller = await _controller.future;

    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(location.latitude, location.longitude),
          zoom: 20.00,
          // tilt: 90.0,
          // bearing: 45.0,
        ),
      ),
    );
    setState((){
      myLocation = location;
      gotlocation = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: _kGooglePlex,
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                  
                },
                buildingsEnabled: true,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                onCameraMove: _onCameraMove,
                polylines: _polylines,
              ),
              //code for water ripple effect and distance
              // Positioned(
              //     top: 30.0,
              //     left: 20,
              //     child: Column(
              //       //mainAxisAlignment: MainAxisAlignment.start,
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: [
              //         Container(
              //           child: const Text('Distance', style: TextStyle(color: Colors.grey),),
              //         ),
              //         Row(
              //           //mainAxisAlignment: MainAxisAlignment.end,
              //           crossAxisAlignment: CrossAxisAlignment.end,
              //           children: [
              //             Text('23', style: TextStyle(fontSize: 60.0, color: Colors.redAccent, fontWeight: FontWeight.bold),),
              //             Text('mtrs', style: TextStyle(fontSize: 20.0, color: Colors.redAccent),),
              //           ],
              //         )
              //       ],
              //     )
              // ),
              // Center(
              //   child: Container(height: 200, width: 200, child: WaterRipple()),
              // ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => const NewRoad()));
          // print(_lastMapPosition.latitude);
          // print(_lastMapPosition.longitude);
          //addCircle(_lastMapPosition.latitude, _lastMapPosition.longitude);
        },
        tooltip: 'Add',
        child: const Icon(Icons.add),
      ),
    );
  }
}
//Hive.deleteFromDisk();