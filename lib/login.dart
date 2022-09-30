import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController _email = TextEditingController();
  TextEditingController _password = TextEditingController();

  Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn(scopes: ['email']).signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.0),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:  [
            Text("Hello welcome back!", style: TextStyle(fontSize: 37.0, fontWeight: FontWeight.bold),),
            SizedBox(height: 10.0,),
            Text("Sign to Continue", style: TextStyle(fontSize: 15.0),),
            SizedBox(height: 30.0,),
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: TextField(
                style: const TextStyle(color: Colors.black),
                controller: _email,
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
            ),
            SizedBox(height: 20.0,),
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: TextField(
                style: const TextStyle(color: Colors.black),
                controller: _password,
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
            ),
            SizedBox(height: 20.0,),
            ElevatedButton(
                onPressed: () {},
                style: ButtonStyle(
                  minimumSize: MaterialStateProperty.all(Size((MediaQuery.of(context).size.width), 50)),
                  backgroundColor: MaterialStateProperty.all(Colors.black),
                ),
                child: const Text('Login to my account', style: TextStyle(color: Colors.white),)
            ),
            OutlinedButton(
              child: Text("Google"),
              onPressed: () async {
                print("login using google");
                await signInWithGoogle();
              },
              style: ButtonStyle(
                shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
            )
          ],
        ),
      ),
    );
  }
}
