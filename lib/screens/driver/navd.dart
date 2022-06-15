import 'package:bus_tracker_aw/general.dart';
import 'package:bus_tracker_aw/screens/driver/mapd.dart';
import 'package:bus_tracker_aw/screens/driver/reports.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../login.dart';

class NavDriverPage extends StatefulWidget {
  @override
  State<NavDriverPage> createState() => _NavDriverPageState();
}

class _NavDriverPageState extends State<NavDriverPage> {
  int _selectedIndex = 0;
  String userFullName = "";
  static final List<Widget> _widgetOptions = <Widget>[
    MapDriverPage(),
    ReportsPage()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    setName();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          primary: false,
          centerTitle: false,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          flexibleSpace: Container(
            alignment: Alignment.centerLeft,
            margin: const EdgeInsets.only(left: 15),
            child: Text(
              "\u{1F44B} $userFullName",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 18,
              ),
              textAlign: TextAlign.end,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.logout_rounded,
                color: Colors.grey,
              ),
              onPressed: () async {
                await CurrentSession.account
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
              icon: Icon(Icons.report),
              label: 'Reports',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.amber[800],
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  Future<void> setName() async {
    await CurrentSession.account.get().then((value) {
      setState(() {
        userFullName = value.name;
      });
      if (kDebugMode) {
        print(value.name);
      }
    });
  }
}
