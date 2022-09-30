import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:testing_isolate/model/getbearing.dart';

class ListOfSpeedBrakers extends StatefulWidget {
  final String head;
  final Map<String, dynamic> speedbrakersasmap;
  final String roadid;
  const ListOfSpeedBrakers({Key? key, required this.head, required this.speedbrakersasmap, required this.roadid}) : super(key: key);

  @override
  State<ListOfSpeedBrakers> createState() => _ListOfSpeedBrakersState();
}

class _ListOfSpeedBrakersState extends State<ListOfSpeedBrakers> {
  var db = FirebaseFirestore.instance;
  List<Widget> allSpdBrakers = [];
  String head = "";
  List<String> speedBrakers = [];
  Map<String, dynamic> speedbrakersasmap = {};
  @override
  void initState() {
    setState((){
      head = widget.head;
      speedbrakersasmap = {
        ...widget.speedbrakersasmap
      };
    });
    showSpeedBrakers();
  }
  Map<String, dynamic> createNewMap(tempSpeedBrakers2){
    Map<String, dynamic> tempspeedbrakersasmap = {};
    for(int j = 0; j < tempSpeedBrakers2.length; j++){
      tempspeedbrakersasmap[tempSpeedBrakers2[j]] = speedbrakersasmap[tempSpeedBrakers2[j]];
      var coordinates = tempspeedbrakersasmap[tempSpeedBrakers2[j]]["coordinates"];
      if(j == 0){
        tempspeedbrakersasmap[tempSpeedBrakers2[j]]["previousnode"] = {
          "cellname": "",
          "bearing": -1
        };
        var nextnodeCoordinates = speedbrakersasmap[tempSpeedBrakers2[j+1]]["coordinates"];
        tempspeedbrakersasmap[tempSpeedBrakers2[j]]["nextnode"] = {
          "cellname": tempSpeedBrakers2[j+1],
          "bearing": getBearing(coordinates[0], coordinates[1], nextnodeCoordinates[0], nextnodeCoordinates[1])
        };
      }
      else {
        if(j == tempSpeedBrakers2.length - 1){
          var previousnodeCoordinates = speedbrakersasmap[tempSpeedBrakers2[j-1]]["coordinates"];
          tempspeedbrakersasmap[tempSpeedBrakers2[j]]["previousnode"] = {
            "cellname": tempSpeedBrakers2[j-1],
            "bearing": getBearing(coordinates[0], coordinates[1], previousnodeCoordinates[0], previousnodeCoordinates[1])
          };
          tempspeedbrakersasmap[tempSpeedBrakers2[j]]["nextnode"] = {
            "cellname": "",
            "bearing": -1
          };
        }
        else {
          var nextnodeCoordinates = speedbrakersasmap[tempSpeedBrakers2[j+1]]["coordinates"];
          var previousnodeCoordinates = speedbrakersasmap[tempSpeedBrakers2[j-1]]["coordinates"];
          tempspeedbrakersasmap[tempSpeedBrakers2[j]]["previousnode"] = {
            "cellname": tempSpeedBrakers2[j-1],
            "bearing": getBearing(coordinates[0], coordinates[1], previousnodeCoordinates[0], previousnodeCoordinates[1])
          };
          tempspeedbrakersasmap[tempSpeedBrakers2[j]]["nextnode"] = {
            "cellname": tempSpeedBrakers2[j+1],
            "bearing": getBearing(coordinates[0], coordinates[1], nextnodeCoordinates[0], nextnodeCoordinates[1])
          };
        }

      }
    }
    return tempspeedbrakersasmap;
  }
  void rearrangeSpeedBrakers(item, index) {
    List<String> tempSpeedBrakers2 = [...speedBrakers];
    if(item != null){
      var itemDraged = item as Map;
      var foundatindex = tempSpeedBrakers2.indexOf(itemDraged["cellName"]);
      tempSpeedBrakers2.removeAt(foundatindex);
      tempSpeedBrakers2.insert(foundatindex < index ? index-1 : index, itemDraged["cellName"]);
      Map<String, dynamic> tempspeedbrakersasmap = createNewMap(tempSpeedBrakers2);
      setState((){
        head = tempSpeedBrakers2[0];
        speedbrakersasmap = {...tempspeedbrakersasmap};
        speedBrakers = [...tempSpeedBrakers2];
        showSpeedBrakers();
      });
    }
  }
  void showSpeedBrakers(){
    var ourRoad = head;
    List<Widget> allSpeedBrakers = [];
    List<String> tempSpeedBrakers = [];
    int i = 0;
    while(ourRoad != ""){
      tempSpeedBrakers.add(ourRoad);
      int index = i;
      var speedbrakerCoordinate = speedbrakersasmap[ourRoad];
      Widget speedBraker = Container(
        color: Colors.white,
        child: Column(
          children: [
             DragTarget(
              builder: (context, candidateItems, rejectedItems) {
                print(candidateItems);
                return Container(
                  width: MediaQuery.of(context).size.width,
                  child: Text('------'),
                  color: candidateItems.isNotEmpty ? Colors.black87 : Colors.red,
                );
              },
              onAccept: (item) {
                print(item);
                print(index);
                rearrangeSpeedBrakers(item, index);
              },
            ),
            Row(
              children: [
                Image.asset('assets/icons8-bumpy-road-sign-96.png', width: 40.0,),
                const SizedBox(
                  width: 10.0,
                ),
                Expanded(flex: 1,child: Text(speedbrakerCoordinate["cellName"], style: TextStyle(fontSize: 20.0),),),
                const Icon(Icons.move_down_outlined, size: 30.0,),
                const SizedBox(
                  width: 10.0,
                ),
                Container(
                  child: GestureDetector(
                    onTap: (){
                      List<String> tempSpeedBrakers2 = [...speedBrakers];
                      print(tempSpeedBrakers2[index]);
                      //db.collection("speedbrakerdetection").doc("jgvj").delete()
                      //tempSpeedBrakers2.removeAt(index);
                      // Map<String, dynamic> tempspeedbrakersasmap = createNewMap(tempSpeedBrakers2);
                      // setState((){
                      //   head = tempSpeedBrakers2[0];
                      //   speedbrakersasmap = {...tempspeedbrakersasmap};
                      //   speedBrakers = [...tempSpeedBrakers2];
                      //   showSpeedBrakers();
                      // });
                    },
                    child: const Icon(Icons.delete, size: 30.0,),
                  ),
                ),
                const SizedBox(
                  width: 10.0,
                ),
              ],
            ),
            const Divider(
              color: Colors.black87,
            ),
            Row(
              children: [
                Column(
                  children: [
                    Text('Previous node'),
                    Text("${speedbrakerCoordinate["previousnode"]["cellname"] == "" ? "nil" : speedbrakerCoordinate["previousnode"]["cellname"]}")
                  ],
                ),
                Column(
                  children: [
                    Text('Next node'),
                    Text("${speedbrakerCoordinate["nextnode"]["cellname"] == "" ? "nil" : speedbrakerCoordinate["nextnode"]["cellname"] }")
                  ],
                )
              ],
            ),
            DragTarget(
              builder: (context, candidateItems, rejectedItems) {
                print(candidateItems);
                return Container(
                  width: MediaQuery.of(context).size.width,
                  child: Text('------'),
                  color: candidateItems.isNotEmpty ? Colors.black87 : Colors.red,
                );
              },
              onAccept: (item) {
                print(item);
                print(index);
                rearrangeSpeedBrakers(item, index);
              },
            )
          ],
        ),
      );
      allSpeedBrakers.add(
          LongPressDraggable(
            data: speedbrakerCoordinate,
            dragAnchorStrategy: pointerDragAnchorStrategy,
            feedback: Container(child: Text(speedbrakerCoordinate["cellName"]),),
            child: speedBraker,
          )
      );
      allSpeedBrakers.add(
        const SizedBox(
          height: 10.0,
        )
      );
      //image, name, move and delete
      ourRoad = speedbrakerCoordinate["nextnode"]["cellname"];
      i++;
    }
    setState((){
      allSpdBrakers = allSpeedBrakers;
      speedBrakers = [...tempSpeedBrakers];
    });
  }

  @override
  Widget build(BuildContext context) {
    print(speedBrakers);
    return Scaffold(
      backgroundColor: Colors.grey,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Column(
                  children: allSpdBrakers,
                ),
                OutlinedButton(
                  child: Text("Save the order"),
                  onPressed: () async {
                    db.collection("roads").doc(widget.roadid).update({
                      "head": speedBrakers[0]
                    }).then((value) {
                      Future.forEach(speedBrakers, (String element) {
                        if(element != null){

                          db.collection("speedbrakersinroad").doc(element).update(speedbrakersasmap[element]).then(
                                (value) => print("data updated"),
                            onError: (error) => print("update failed"),
                          );
                        }
                      }).then(
                            (value) => Navigator.pop(context),
                        onError: (error) => print("update failed"),
                      );
                    });
                  },
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
