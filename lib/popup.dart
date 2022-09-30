import 'package:flutter/material.dart';

class Popup extends StatefulWidget {
  const Popup({Key? key}) : super(key: key);

  @override
  State<Popup> createState() => _PopupState();
}

class _PopupState extends State<Popup> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Text('data'),
          Text('Do you want to delete or navigate to next page'),
          Row(
            children: [
              OutlinedButton(
                child: Text("Delete"),
                onPressed: () async {},
                style: ButtonStyle(
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                ),
              ),
              OutlinedButton(
                child: Text("Navigate"),
                onPressed: () async {},
                style: ButtonStyle(
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
