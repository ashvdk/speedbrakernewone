
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:testing_isolate/model/getbearing.dart';
import 'components/CirclePainter10.dart';
import 'geohash.dart';
import 'model/speedbrakerinroad.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ffi';
import 'dart:ui';
class MoreSpeedBrakers extends StatefulWidget {
  final SpeedBrakerInRoad speedbraker;
  const MoreSpeedBrakers({Key? key, required this.speedbraker}) : super(key: key);

  @override
  State<MoreSpeedBrakers> createState() => _MoreSpeedBrakersState();
}

class _MoreSpeedBrakersState extends State<MoreSpeedBrakers> {
  var db = FirebaseFirestore.instance;
  @override
  void initState() {
    _determinePosition();
    initializeTargetSpeedBraker();
    getBoxData();
  }
  Set<Circle> _circle = {};
  int precision = 9;
  //Box boxData = Hive.box("Bangalore");
  final Completer<GoogleMapController> _controller = Completer();
  static const LatLng _center = LatLng(12.8924552, 77.529757);
  static const CameraPosition _kGooglePlex = CameraPosition(
    target: _center,
    zoom: 18,
  );
  LatLng _lastMapPosition = _center;
  void _onCameraMove(CameraPosition position) {
    _lastMapPosition = position.target;
  }
  void initializeTargetSpeedBraker(){
    _circle.add(
        Circle(
            circleId: CircleId(widget.speedbraker.cellName),
            center: LatLng(widget.speedbraker.coordinates[0], widget.speedbraker.coordinates[1]),
            radius: 2.3,
            strokeColor: Colors.black87
        )
    );
    setState((){});
  }
  void getBoxData(){
    Set<Circle> tempCircles = {..._circle};
    db.collection("speedbrakerdetection").where("targetCoordinates.cellname", isEqualTo: widget.speedbraker.cellName).get().then(
          (res){
        var data = res.docs.toList();
        data.forEach((e){
          final cellDetails = e.data() as Map<String, dynamic>;
          print(cellDetails["cellName"]);
          print("${cellDetails["coordinates"][0]} ${cellDetails["coordinates"][1]}");
          tempCircles.add(
              Circle(
                  circleId: CircleId(cellDetails["cellName"]),
                  center: LatLng(cellDetails["coordinates"][0], cellDetails["coordinates"][1]),
                  radius: 2.3,
                  strokeColor: Colors.red
              )
          );
        });
        setState((){
          _circle = {...tempCircles};
        });
      },
      onError: (e) => print("Error completing: $e"),
    );
    db.collection("speedbrakerdetection").where("adjacentCoordinates.cellname", isEqualTo: widget.speedbraker.cellName).get().then(
          (res){
        var data = res.docs.toList();
        data.forEach((e){
          final cellDetails = e.data() as Map<String, dynamic>;
          print(cellDetails["cellName"]);
          print("${cellDetails["coordinates"][0]} ${cellDetails["coordinates"][1]}");
          tempCircles.add(
              Circle(
                  circleId: CircleId(cellDetails["cellName"]),
                  center: LatLng(cellDetails["coordinates"][0], cellDetails["coordinates"][1]),
                  radius: 2.3,
                  strokeColor: Colors.red
              )
          );
        });
        setState((){
          _circle = {...tempCircles};
        });
      },
      onError: (e) => print("Error completing: $e"),
    );
    // List<Cell> circles =  boxData.values.where((element) {
    //     return element.targetCoordinates["cellname"] == widget.speedbraker.cellName || element.adjacentCoordinates["cellname"] == widget.speedbraker.cellName;
    // }).toList().cast<Cell>();
    //
    //
    // circles.forEach((element) {
    //   String cellname = element.cellName;
    //   tempCircles.add(
    //       Circle(
    //         circleId: CircleId(cellname),
    //         center: LatLng(element.coordinates[0], element.coordinates[1]),
    //         radius: 2.3,
    //           strokeColor: Colors.red
    //       )
    //   );
    // });

  }
  void addCircle(double lat, double lng){
    var newLat = lat;
    var newLng = lng;
    Set<Circle> tempCircles = {..._circle};
    String cellName = Geohash.encode(lat, lng);
    var bearing = Geolocator.bearingBetween(lat, lng, widget.speedbraker.coordinates[0], widget.speedbraker.coordinates[1]);
    bearing = bearing < 0.0 ? (bearing + 360.0) : bearing;
    if(cellName != widget.speedbraker.cellName){
      //var myCell = boxData.get(cellName);
      db.collection("speedbrakerdetection").doc(cellName).get().then(
            (DocumentSnapshot doc) {
          if(doc.exists){
            print("speed braker exists ${widget.speedbraker.cellName}");
            final data = doc.data() as Map<String, dynamic>;
            if(data["targetCoordinates"]["cellname"] != widget.speedbraker.cellName){
              newLat = data["coordinates"][0];
              newLng = data["coordinates"][1];
              db.collection("speedbrakerdetection").doc(cellName).update({"adjacentCoordinates": {
                "cellname": widget.speedbraker.cellName,
                "bearing": bearing
              }}).then((value){
                tempCircles.add(
                    Circle(
                        circleId: CircleId(cellName),
                        center: LatLng(newLat, newLng),
                        radius: 2.3,
                        strokeColor: Colors.red
                    )
                );
                setState((){
                  _circle = {...tempCircles};
                });
              });
              //boxData.put(cellName, cell);
            }
          }
          else {
            db.collection("speedbrakerdetection").doc(cellName).set({
              "cellName": cellName,
              "area": cellName.substring(0, 5),
              "coordinates": [lat, lng],
              "targetCoordinates": {"cellname": widget.speedbraker.cellName, "bearing": bearing },
              "adjacentCoordinates": {}
            }).then((value) => {

              tempCircles.add(
                  Circle(
                      circleId: CircleId(cellName),
                      center: LatLng(newLat, newLng),
                      radius: 2.3,
                      strokeColor: Colors.red
                  )
              ),
              setState((){
                _circle = {...tempCircles};
              })
            });
          }
        },
        onError: (e) => print("Error getting document: $e"),
      );
      // if(myCell != null){
      //   if(myCell.targetCoordinates["cellname"] != widget.speedbraker.cellName){
      //     newLat = myCell.coordinates[0];
      //     newLng = myCell.coordinates[1];
      //     var cell = Cell(cellName: myCell.cellName, coordinates: [...myCell.coordinates], targetCoordinates: {...myCell.targetCoordinates}, adjacentCoordinates: {
      //       "cellname": widget.speedbraker.cellName,
      //       "bearing": bearing
      //     }, branchOne: {}, branchTwo: {} );
      //     print(cell.cellName);
      //     print(cell.coordinates);
      //     print(cell.targetCoordinates);
      //     print(cell.adjacentCoordinates);
      //     db.collection("speedbrakerdetection").doc(myCell.cellName).update({"adjacentCoordinates": {
      //       "cellname": widget.speedbraker.cellName,
      //       "bearing": bearing
      //     }});
      //     boxData.put(cellName, cell);
      //   }
      // }
      // else {
      //   var cell = Cell(cellName: cellName, coordinates: [lat, lng], targetCoordinates: {"cellname": widget.speedbraker.cellName, "bearing": bearing },adjacentCoordinates: {}, branchOne: {}, branchTwo: {} );
      //   print(cell.cellName);
      //   print(cell.coordinates);
      //   print(cell.targetCoordinates);
      //   db.collection("speedbrakerdetection").doc(cellName).set({
      //     "cellName": cell.cellName,
      //     "coordinates": [lat, lng],
      //     "targetCoordinates": {"cellname": widget.speedbraker.cellName, "bearing": bearing },
      //     "adjacentCoordinates": {}
      //   });
      //   boxData.put(cellName, cell);
      // }


    }
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
          zoom: 17.00,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = (MediaQuery.of(context).size.width) / 2;
    double height = MediaQuery.of(context).size.height;
    var padding = MediaQuery.of(context).padding;
    double newheight = (height - padding.top - padding.bottom) / 2;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            GoogleMap(
              mapType: MapType.satellite,
              initialCameraPosition: _kGooglePlex,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onCameraMove: _onCameraMove,
              circles: _circle,
            ),
            CustomPaint(
              painter: CirclePainte(precision: 9, x: width, y: newheight),
            ),
            Center(
              child: Image.asset(
                'assets/circle.png',
                width: 40.0,
              ),
            ),
            Positioned(
                top: 20.0,
                left: 20.0,
                child:  ElevatedButton(
                    onPressed: () async {
                      //Navigator.pop(context);
                      // print(widget.speedbraker.previousnode["cellname"]);
                      // print(widget.speedbraker.nextnode["cellname"]);
                      // var previousnode;
                      // var nextnode;
                      // if(widget.speedbraker.previousnode["cellname"] != ""){
                      //   var temppreviousnode = await db.collection("speedbrakersinroad").doc(widget.speedbraker.previousnode["cellname"]).get();
                      //   previousnode = temppreviousnode.data() as Map<String, dynamic>;
                      // }
                      // var tempnextnode;
                      // if(widget.speedbraker.nextnode["cellname"] != ""){
                      //   var tempnextnode = await db.collection("speedbrakersinroad").doc(widget.speedbraker.nextnode["cellname"]).get();
                      //   nextnode = tempnextnode.data() as Map<String, dynamic>;
                      // }
                      // if(previousnode != null && nextnode != null){
                      //   previousnode["nextnode"] = {
                      //     "cellname": nextnode["cellName"],
                      //     "bearing": getBearing(previousnode["coordinates"][0], previousnode["coordinates"][1], nextnode["coordinates"][0], nextnode["coordinates"][1])
                      //   };
                      //   nextnode["previousnode"] = {
                      //     "cellname": previousnode["cellName"],
                      //     "bearing": getBearing(nextnode["coordinates"][0], nextnode["coordinates"][1], previousnode["coordinates"][0], previousnode["coordinates"][1])
                      //   };
                      //   print(previousnode);
                      //   print(nextnode);
                      // }
                      // if(nextnode == null){
                      //   previousnode["nextnode"] = {
                      //     "cellname": "",
                      //     "bearing": -1
                      //   };
                      // }
                      // if(previousnode == null){
                      //   nextnode["previousnode"] = {
                      //     "cellname": "",
                      //     "bearing": -1
                      //   };
                      // }
                      // db.collection("speedbrakersinroad").doc(widget.speedbraker.cellName).delete().then((value){
                      //
                      // });
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.black),
                    ),
                    child: Icon(Icons.delete)
                )
            ),
            Positioned(
                bottom: 20.0,
                left: 20.0,
                child:  ElevatedButton(
                    onPressed: (){
                      print("Clicking to add more sped brakers");
                      print(widget.speedbraker);
                      addCircle(_lastMapPosition.latitude, _lastMapPosition.longitude);
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.black),
                    ),
                    child: Icon(Icons.add)
                )
            )
          ],
        ),
      ),
    );
  }
}
