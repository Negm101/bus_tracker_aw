import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:bus_tracker_aw/models/user.dart';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

import '../../general.dart';
import '../login.dart';

class MapDriverPage extends StatefulWidget {
  @override
  State<MapDriverPage> createState() => _MapDriverPageState();
}

class _MapDriverPageState extends State<MapDriverPage> {
  LatLng mapCenter = LatLng(2.9252, 101.6376);
  MapController _mapController = MapController();
  LatLng pointer = LatLng(2.9252, 101.6376);
  List<Marker> markers = [];
  late Database database;
  Document? documentList;

  Location location = Location();

  late bool _serviceEnabled;
  late PermissionStatus _permissionGranted;
  LocationData? _locationData;
  StreamSubscription<LocationData>? locationSubscription;
  // Realtime location

  Realtime? _realtime;
  RealtimeSubscription? _subscription;
  LocationReal? _locationReal;

  @override
  void initState() {
    initLocServ();
    location.changeSettings(interval: 10000);
    location.enableBackgroundMode(enable: true);
    database = Database(CurrentSession.client);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          leadingWidth: 100,
          leading: const Align(
            alignment: Alignment.center,
            child: Text(
              ' \u{1F44B} ',
              style: TextStyle(color: Colors.grey, fontSize: 21),
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
        body: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            FlutterMap(
              options: MapOptions(
                  controller: _mapController,
                  center: mapCenter,
                  swPanBoundary: LatLng(2.8928, 101.6307),
                  slideOnBoundaries: true,
                  maxZoom: 17,
                  minZoom: 15),
              layers: [
                TileLayerOptions(
                  urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayerOptions(
                  markers: [
                    Marker(
                        width: 80.0,
                        height: 80.0,
                        point: pointer,
                        builder: (ctx) => const Icon(
                              Icons.circle,
                              color: Colors.redAccent,
                              size: 16,
                            )),
                  ],
                ),
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Card(
                    color: Colors.white,
                    margin: const EdgeInsets.only(
                        left: 20, right: 20, bottom: 20, top: 20),
                    child: Column(
                      children: [
                        Text("device : " +
                            pointer.latitude.toString() +
                            ", " +
                            pointer.longitude.toString()),
                        _locationReal == null
                            ? const SizedBox(
                                height: 0,
                              )
                            : Text("server : " +
                                _locationReal!.latitude.toString() +
                                ", " +
                                _locationReal!.longitude.toString()),
                      ],
                    )),
                Card(
                  color: Colors.white,
                  margin:
                      const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                          style: ButtonStyle(
                              padding: MaterialStateProperty.all<EdgeInsets>(
                                  const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 30)),
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Colors.lightGreenAccent)),
                          onPressed: () {
                            locationSubscription = location.onLocationChanged
                                .listen((LocationData locationData) {
                              setState(() {
                                pointer = LatLng(locationData.latitude!,
                                    locationData.longitude!);
                                Future result = database.updateDocument(
                                    collectionId: "6202ad43b4091862b744",
                                    documentId: "620fe71946cc2b5136fe",
                                    data: {
                                      "latitude": locationData.latitude!,
                                      "longitude": locationData.longitude!,
                                    });
                                result.then((response) {
                                  print("location updated");
                                }).catchError((error) {
                                  print(error.response);
                                });
                              });
                            });
                          },
                          child: const Text(
                            "Start",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          )),
                      TextButton(
                          style: ButtonStyle(
                              padding: MaterialStateProperty.all<EdgeInsets>(
                                  const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 30)),
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Colors.redAccent)),
                          onPressed: () {
                            locationSubscription?.cancel();
                          },
                          child: const Text(
                            "Stop",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          )),
                      TextButton(
                          style: ButtonStyle(
                              padding: MaterialStateProperty.all<EdgeInsets>(
                                  const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 30)),
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Colors.lightBlueAccent)),
                          onPressed: () {
                            // Realtime
                            _realtime = Realtime(CurrentSession.client);
                            _subscription = _realtime!
                                .subscribe(['documents.620fe71946cc2b5136fe']);
                            _subscription?.stream.listen((response) {
                              _locationReal =
                                  LocationReal.fromJson(response.payload);
                              pointer = LatLng(_locationReal!.latitude!, _locationReal!.longitude!);
                            });
                          },
                          onLongPress: () {
                            _subscription?.close();
                          },
                          child: const Text(
                            "Read Stream",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    locationSubscription?.cancel();
    super.dispose();
  }

  void initLocServ() async {
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationData = await location.getLocation();
  }
}
