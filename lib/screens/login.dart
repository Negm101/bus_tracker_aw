import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:bus_tracker_aw/screens/driver/mapd.dart';
import 'package:bus_tracker_aw/screens/driver/navd.dart';
import 'package:bus_tracker_aw/screens/student/map.dart';
import 'package:bus_tracker_aw/screens/student/nav.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../general.dart';

class LoginPage extends StatelessWidget {
  static const String endpoint = "http://192.168.1.102/v1";
  static const String projectId = "mmu-bus-tracker";

  final TextEditingController emailController =
      TextEditingController(text: "najm23@gmail.com");
  final TextEditingController passwordController =
      TextEditingController(text: "123456789");
  String userRole = "null";
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            //mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //const SizedBox(height: 75),
              /*Container(
                width: 200.00,
                height: 200.00,
                decoration: new BoxDecoration(
                  image: const DecorationImage(
                    image: AssetImage('assets/images/logo.png'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),*/
              Container(
                padding: const EdgeInsets.fromLTRB(25, 10, 25, 10),
                child: TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person),
                    filled: true,
                    fillColor: Color(0xFFF4F4F4),
                    labelText: 'User Name',
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(25, 10, 25, 50),
                child: TextField(
                  obscureText: true,
                  controller: passwordController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.lock),
                    filled: true,
                    fillColor: Color(0xFFF4F4F4),
                    labelText: 'Password',
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ButtonStyle(
                      padding: MaterialStateProperty.all<EdgeInsets>(
                          const EdgeInsets.symmetric(vertical: 12)),
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.blueGrey)),
                  onPressed: () async {
                    CurrentSession.client
                        .setEndpoint(endpoint)
                        .setProject(projectId);
                    CurrentSession.account = Account(CurrentSession.client);
                    Future result = CurrentSession.account.createSession(
                      email: emailController.text,
                      password: passwordController.text,
                    );

                    await result.then((response) async {
                      CurrentSession.session = response as Session;
                      if (CurrentSession.client != null &&
                          CurrentSession.account != null &&
                          CurrentSession.session != null) {
                        await setRole(CurrentSession.session.userId);
                        print(userRole);
                        if (userRole == 'student') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => NavPage()),
                          );
                        } else if (userRole == 'driver') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => MapDriverPage()),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text(
                                  "Something is wrong with your account, please contact the unversity")));
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Something is wrong")));
                      }
                    }).catchError((error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error.response.toString())));
                      print(error.response);
                    });
                  },
                  child: const Text("Login"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> setRole(String userId) async {
    Database _database = Database(CurrentSession.client);
    Future result = _database.getDocument(
      collectionId: 'roles',
      documentId: userId,
    );

    await result.then((response) {
      Document rolee = response as Document;
      userRole = rolee.data['role'];
      if (kDebugMode) {
        print(userRole);
      }
    }).catchError((error) {
      if (kDebugMode) {
        print(error.response.toString());
      }
    });
  }
}
