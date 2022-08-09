import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:bus_tracker_aw/helpers/ngrok.dart';
import 'package:bus_tracker_aw/models/ngrokEndpoint.dart';
import 'package:bus_tracker_aw/screens/driver/mapd.dart';
import 'package:bus_tracker_aw/screens/student/nav.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../general.dart';

class LoginPage extends StatefulWidget {
  static const String projectId = "mmu-bus-tracker";

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController =
      TextEditingController(text: "gomaa101@gmail.com");

  final TextEditingController passwordController =
      TextEditingController(text: "123456789");
  late String endpoint;
  String userRole = "null";
  bool isLoading = false;
  final NgRok _ngRok =
      NgRok(apikey: "2BZv5fAjsIAPZatP3Q3pC8M9IFs_2fzDB8hkyfEdogEXuhhq1");
  @override
  void initState() {
    super.initState();
    endpoint = "http://192.168.1.102/v1";
    //setEndpoint();
  }

  Future<void> setEndpoint() async {
    /*await _ngRok.listEnpoints().then((value) {
      endpoint = "${value.endpoints![0].publicUrl!}/v1";
    }).onError((error, stackTrace) {
      print("local");
      endpoint = "192.168.1.102/v1";
    });*/
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              //mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 25),
                  child: SvgPicture.asset(
                    'assets/svgs/undraw_sign_in_re_o58h.svg',
                    width: MediaQuery.of(context).size.width / 1.75,
                  ),
                ),
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
                      setState(() {
                        isLoading = true;
                      });
                      CurrentSession.client
                          .setEndpoint(endpoint)
                          .setProject(LoginPage.projectId);
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
                              MaterialPageRoute(
                                  builder: (context) => NavPage()),
                            );
                          } else if (userRole == 'driver') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => MapDriverPage()),
                            );
                          } else {
                            setState(() {
                              isLoading = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "Something is wrong with your account, please contact the unversity")));
                          }
                        } else {
                          setState(() {
                            isLoading = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Something is wrong")));
                        }
                      }).catchError((error) {
                        setState(() {
                          isLoading = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error.response.toString())));
                        print(error);
                      });
                    },
                    child: isLoading
                        ? const SizedBox(
                            width: 25,
                            height: 25,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text("Login"),
                  ),
                ),
              ],
            ),
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
