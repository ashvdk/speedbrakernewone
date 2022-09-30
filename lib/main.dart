import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:testing_isolate/login.dart';
import 'firebase_options.dart';
import 'myhomepage.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  bool isSignedIn = false;
  @override
  void initState() {
    FirebaseAuth.instance
        .authStateChanges()
        .listen((User? user) {
      if (user == null) {
        setState((){
          isSignedIn = false;
        });
      } else {
        print('User is signed in!');
        print(user);
        setState((){
          isSignedIn = true;
        });
      }
    });
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        body: isSignedIn ? MyHomePage() : Login(),
      ),
    );
  }
}


