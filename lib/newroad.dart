import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:testing_isolate/listofspeedbrakers.dart';

import 'components/CirclePainter10.dart';
import 'geohash.dart';
import 'model/speedbrakerinroad.dart';
import 'morespeedbrakers.dart';


class NewRoad extends StatefulWidget {
  final String roadName;
  const NewRoad({Key? key, this.roadName = ""}) : super(key: key);

  @override
  State<NewRoad> createState() => _NewRoadState();
}
enum TtsState { playing, stopped, paused, continued }
class _NewRoadState extends State<NewRoad> {
  var db = FirebaseFirestore.instance;
  TextEditingController _roadName = TextEditingController();
  List speedBrakerInRoad = [];
  List<String> allSpeedBrakersinRoad = [];
  Set<Circle> _circle = {};
  Set<Polyline> _polylines = {};
  late Position myLocation;
  bool gotlocation = false;
  String head = "";
  Map<String, dynamic> speedbrakersasmap2 = {};
  String roadName = "";
  late final roadsListener;
  late final speedBrakerListener;
  bool shoPopup = false;
  //Google Map Settings
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
  //Google Map Seetings end

  @override
  void initState() {

    _determinePosition();
    if(widget.roadName != ""){
      drawRoads();
      listenForRoads();
      listenForSpeedBrakerChanges();
    }
    setState((){
      roadName = widget.roadName;
    });
  }
  void listenForRoads(){
    final docRef = db.collection("roads").doc(widget.roadName);
    roadsListener = docRef.snapshots().listen(
      (event) {
        print("----------------Listening for changes in the road-------------------");
        print(event.data());
        drawRoads();
      },
      onError: (error) => print("Listen failed: $error"),
    );
  }
  void listenForSpeedBrakerChanges(){
    speedBrakerListener = db.collection("speedbrakersinroad").where("roadid", isEqualTo: widget.roadName).snapshots().listen((event) {
      print("----------------Listening for changes in the speedbrakers-------------------");
      drawRoads();
    });
  }
  @override
  void dispose(){
    roadsListener.cancel();
    speedBrakerListener.cancel();
    super.dispose();
  }
  void drawRoads() async {
    Set<Polyline> tempPolylines = {};
    Set<Circle> tempCircles = {};
    List<LatLng> listofspeedbrakers = []; //to draw polyline
    List<String> tempallSpeedBrakers = [];
    Map<String, dynamic> speedbrakersasmap = {};
    var tempRoad = await db.collection("roads").doc(widget.roadName).get();
    var road = tempRoad.data() as Map<String, dynamic>;
    var tempSpeedBrakers = await db.collection("speedbrakersinroad").where("roadid", isEqualTo: widget.roadName).get();
    var speedbrakers = tempSpeedBrakers.docs.toList();
    speedbrakers.forEach((element) {
      final speedbraker = element.data() as Map<String, dynamic>;
      speedbrakersasmap[speedbraker["cellName"]] = speedbraker;
    });
    print(road);
    var ourRoad = road["head"];
    while(ourRoad != ""){
      var speedbrakerCoordinate = speedbrakersasmap[ourRoad];
      print(speedbrakerCoordinate);
      listofspeedbrakers.add(LatLng(speedbrakerCoordinate["coordinates"][0], speedbrakerCoordinate["coordinates"][1]));
      tempallSpeedBrakers.add(speedbrakerCoordinate["cellName"]);
      tempCircles.add(
          Circle(
              circleId: CircleId(speedbrakerCoordinate["cellName"]),
              center: LatLng(speedbrakerCoordinate["coordinates"][0], speedbrakerCoordinate["coordinates"][1]),
              radius: 2.3,
              consumeTapEvents: true,
              onTap: (){
                var spdbraker = SpeedBrakerInRoad(roadName: speedbrakerCoordinate["roadid"], cellName: speedbrakerCoordinate["cellName"], coordinates: speedbrakerCoordinate["coordinates"], nextnode: speedbrakerCoordinate["nextnode"], previousnode: speedbrakerCoordinate["previousnode"]);
                Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => MoreSpeedBrakers(speedbraker: spdbraker)));
              }
          )
      );
      ourRoad = speedbrakerCoordinate["nextnode"]["cellname"];
    }
    tempPolylines.add(
        Polyline(
          polylineId: PolylineId(widget.roadName),
          visible: true,
          //latlng is List<LatLng>
          points: listofspeedbrakers,
          color: Colors.blue,
        )
    );
    setState((){
      head = road["head"];
      speedbrakersasmap2 = speedbrakersasmap;
      _polylines = {...tempPolylines};
      _circle = {...tempCircles};
      speedBrakerInRoad = [...speedBrakerInRoad, ...listofspeedbrakers];
      allSpeedBrakersinRoad = [...tempallSpeedBrakers];
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
          zoom: 17.00,
        ),
      ),
    );
    setState((){
      myLocation = location;
      gotlocation = true;
    });
  }

  void addCircle(double lat, double lng){
    Set<Circle> tempCircles = {..._circle};
    List<LatLng> tempSpeedBrakerInRoad = [...speedBrakerInRoad, LatLng(lat, lng)];
    List tempallSpeedBrakers = [...allSpeedBrakersinRoad];
    //tempSpeedBrakerInRoad.add(LatLng(lat, lng));
    String cellName = Geohash.encode(lat, lng);
    var cell = SpeedBrakerInRoad(roadName: roadName, cellName: cellName, coordinates: [lat, lng], nextnode: {"cellname": "", "bearing": -1}, previousnode: {"cellname": "", "bearing": -1});
    //print(tempPreviousCell["cellName"]);
    var tempPreviousCell;
    print(tempallSpeedBrakers);
    if(tempallSpeedBrakers.isNotEmpty){
      var previousCellName = tempallSpeedBrakers[tempallSpeedBrakers.length - 1];
      db.collection("speedbrakersinroad").doc(previousCellName).get().then((DocumentSnapshot doc){
        if(doc.exists){
          final data = doc.data() as Map<String, dynamic>;
          var bearing1 = Geolocator.bearingBetween(data["coordinates"][0], data["coordinates"][1], lat, lng);
          bearing1 = bearing1 < 0.0 ? (bearing1 + 360.0) : bearing1;

          db.collection("speedbrakersinroad").doc(previousCellName).update({
            "nextnode": {
              "cellname": cellName,
              "bearing": bearing1
            }
          }).then((value) {
            var bearing2 = Geolocator.bearingBetween(lat, lng, data["coordinates"][0], data["coordinates"][1]);
            bearing2 = bearing2 < 0.0 ? (bearing2 + 360.0) : bearing2;
            db.collection("speedbrakersinroad").doc(cellName).set({
              "roadid": roadName,
              "cellName": cellName,
              "area": cellName.substring(0, 5),
              "coordinates": [lat, lng],
              "nextnode": {"cellname": "", "bearing": -1},
              "previousnode": {
                "cellname": previousCellName,
                "bearing": bearing2
              }
            }).then((value) {
              tempallSpeedBrakers.add(cellName);
            });
          });
        }
      });
    }
    else {
      db.collection("speedbrakersinroad").doc(cellName).set({
        "roadid": roadName,
        "cellName": cellName,
        "area": cellName.substring(0, 5),
        "coordinates": [lat, lng],
        "nextnode": {"cellname": "", "bearing": -1},
        "previousnode": {"cellname": "", "bearing": -1}
      }).then((value) {
        db.collection("roads").doc(roadName).update({"head": cellName}).then((value){});
      });
    }
    tempallSpeedBrakers.add(cellName);
    Set<Polyline> tempPolylines = {};
    tempPolylines.add(
        Polyline(
          polylineId: PolylineId(cellName),
          visible: true,
          //latlng is List<LatLng>
          points: tempSpeedBrakerInRoad,
          color: Colors.blue,
        )
    );
    tempCircles.add(
        Circle(
            circleId: CircleId(cellName),
            center: LatLng(lat, lng),
            radius: 2.3,
            consumeTapEvents: true,
            onTap: (){
              print(cellName);
              //var allneighbours = Geohash.neighbours(cellName);
              Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => MoreSpeedBrakers(speedbraker: cell)));
            }
        )
    );
    // if(tempPreviousCell != null){
    //   print("${tempPreviousCell.cellName} ${tempPreviousCell.previousnode}  ${tempPreviousCell.nextnode}");
    //   speedBrakersinRoad.put(tempPreviousCell.cellName, tempPreviousCell);
    // }
    //speedBrakersinRoad.putAll(entries)
    print(tempallSpeedBrakers);
    setState((){
      _polylines = {...tempPolylines};
      _circle = {...tempCircles};
      speedBrakerInRoad = [...tempSpeedBrakerInRoad];
      allSpeedBrakersinRoad = [...tempallSpeedBrakers];
    });
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
              polylines: _polylines,
            ),
            CustomPaint(
              painter: CirclePainte(precision: 9, x: width, y: newheight),
            ),
            Center(
              child: Image.asset('assets/circle.png', width: 40.0,),
            ),
            roadName.length != 0 ? Container(
                width: MediaQuery.of(context).size.width,
                height: 85,
                padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0),
                child: Container(
                  padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                  decoration: const BoxDecoration(

                    borderRadius: BorderRadius.all(
                        Radius.circular(20.0) //                 <--- border radius here
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Street name", style: TextStyle(color: Colors.greenAccent,)),
                      Text(roadName, style: const TextStyle(color: Colors.lightGreenAccent, fontSize: 25.0, fontWeight: FontWeight.bold),),
                    ],
                  ),
                )
            ) : Container(),
            roadName.length != 0 ?
            Positioned(
                bottom: 0,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                          onPressed: (){
                            addCircle(_lastMapPosition.latitude, _lastMapPosition.longitude);
                          },
                          style: ButtonStyle(
                            minimumSize: MaterialStateProperty.all(const Size(40, 40)),
                            backgroundColor: MaterialStateProperty.all(Colors.black),
                          ),
                          child: const Icon(Icons.add)
                      ),
                      ElevatedButton(
                          onPressed: (){
                            Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => ListOfSpeedBrakers(head: head, speedbrakersasmap: speedbrakersasmap2, roadid: widget.roadName,)));
                          },
                          style: ButtonStyle(
                            minimumSize: MaterialStateProperty.all(const Size(40, 40)),
                            backgroundColor: MaterialStateProperty.all(Colors.black),
                          ),
                          child: const Icon(Icons.view_list)
                      )
                    ],
                  ),
                )
            ) :
            Positioned(
              bottom: 0,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 250,
                padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(40),
                    topLeft: Radius.circular(40),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Street name", style: TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold),),
                    const SizedBox(
                      height: 10.0,
                    ),
                    TextField(
                      style: const TextStyle(color: Colors.black),
                      controller: _roadName,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        // fillColor: Color(0xff394847),
                        // filled: true,

                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                          //borderRadius: BorderRadius.circular(10.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          //borderSide: BorderSide(color: Colors.white, width: 2.0),
                          borderSide: BorderSide(color: Colors.black),
                          //borderRadius: BorderRadius.circular(10.0),
                        ),
                        prefixIcon: Icon(
                          CupertinoIcons.location_solid,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                            flex: 1,
                            child: OutlinedButton(
                              child: Text("Single Lane"),
                              onPressed: () async {
                                //HapticFeedback.heavyImpact();
                                //_PatternVibrate();
                                //Vibration.vibrate(duration: 1000);

                              },
                              style: ButtonStyle(
                                shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                              ),
                            )
                        ),
                        const SizedBox(
                          width: 10.0,
                        ),
                        Expanded(
                            flex: 1,
                            child: OutlinedButton(
                              child: Text("Double Lane"),
                              onPressed: (){

                              },
                              style: ButtonStyle(
                                shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                              ),
                            )
                        ),
                      ],
                    ),
                    OutlinedButton(
                      child: Text("Create"),
                      onPressed: (){
                        db.collection("roads").add({"roadName": _roadName.text}).then((documentSnapshot){
                          print("Added Data with ID: ${documentSnapshot.id}");
                          //var cell = Road(roadName: _roadName.text, head: "", roadtype: "");
                          //road.put(_roadName.text, cell);
                          setState((){
                            roadName = documentSnapshot.id;
                          });
                          print(_roadName.text);
                        });

                      },
                      style: ButtonStyle(
                        shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: (){
      //     addCircle(_lastMapPosition.latitude, _lastMapPosition.longitude);
      //   },
      //   tooltip: 'Add',
      //   child: const Icon(Icons.add),
      // ),
    );
  }
}

//road class will have two properties roadname and head, head represents first speed braker of the road or empty if there are no speed brakers
//speedbraker class has many properties and one of them is next node
//when loading add the speed brakers to a array
//when a adding a speed braker there are two condition
//1. adding first speed braker which will be the head for the road class
//2. all the following speed brakers
//in the first condition first check if the array is empty if its empty then add that to the head of the road and save it in the database
//and if its not then take last cellname from the array then get value of the speedbraker from database and add the current speed braker as next node to that and save both current speed braker and last speed braker in the database
