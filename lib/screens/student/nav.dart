import 'package:bus_tracker_aw/general.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../login.dart';
import 'map.dart';
import 'schedule.dart';
import 'settings.dart';

class NavPage extends StatefulWidget {
  @override
  State<NavPage> createState() => _NavPageState();
}

class _NavPageState extends State<NavPage> {
  int _selectedIndex = 0;
  static final List<Widget> _widgetOptions = <Widget>[
    const MapPage(),
    SchedulePage(),
    SettingsPage()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 100,
        leading: Align(
          alignment: Alignment.center,
          child: Text(
            ' \u{1F44B} ',
            style: const TextStyle(color: Colors.grey, fontSize: 21),
            textAlign: TextAlign.center,
          ),
        ),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout_rounded,
              color: Colors.grey,
            ),
            onPressed: () {
              print(CurrentSession.session.$id);
              CurrentSession.account
                  .deleteSession(sessionId: CurrentSession.session.$id);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          )
        ],
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}
