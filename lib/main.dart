import 'package:bus_tracker_aw/screens/driver/mapd.dart';
import 'package:flutter/material.dart';

import 'screens/login.dart';

void main() {
  runApp(const MMUBusTracker());
}

class MMUBusTracker extends StatelessWidget {
  const MMUBusTracker({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginPage(),
    );
  }
}
