import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:bus_tracker_aw/helpers/transportation_icons_icons.dart';
import 'package:bus_tracker_aw/models/reports.dart';
import 'package:bus_tracker_aw/models/user.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

import '../../general.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../models/bus-stops.dart';
import '../login.dart';

class MapDriverPage extends StatefulWidget {
  @override
  State<MapDriverPage> createState() => _MapDriverPageState();
}

class _MapDriverPageState extends State<MapDriverPage> {
  LatLng mapCenter = LatLng(2.9252, 101.6376);
  late MapController _mapController;
  LatLng pointer = LatLng(2.9252, 101.6376);
  List<Marker> driverLocMarker = [];
  List<Marker> busStopsMarkers = [];
  List<Polyline> polylines = [];
  late Database database;

  //late LocationData locationData;
  Bus? _driverBus;
  bool _isRideActive = false;
  Location location = Location();
  String userFullName = "";
  late bool _serviceEnabled;
  late PermissionStatus _permissionGranted;
  StreamSubscription<LocationData>? locationSubscription;

  bool _isGoButtonEnabled = true;
  @override
  void initState() {
    setName();
    initLocServ();
    location.enableBackgroundMode(enable: true);
    database = Database(CurrentSession.client);
    _loadBusStops();
    _mapController = MapController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
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
                PolylineLayerOptions(polylines: polylines),
                MarkerLayerOptions(markers: busStopsMarkers),
                MarkerLayerOptions(
                  markers: driverLocMarker,
                ),
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Card(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        alignment: Alignment.centerLeft,
                        margin: const EdgeInsets.only(left: 10),
                        child: FutureBuilder(
                          future: _getAvatar(),
                          builder: (context, snapshot) {
                            return GestureDetector(
                              onTap: () {},
                              child: snapshot.hasData && snapshot.data != null
                                  ? CircleAvatar(
                                      backgroundColor: Colors.grey[500],
                                      child: Image.memory(
                                        snapshot.data as Uint8List,
                                        scale: 18,
                                      ),
                                    )
                                  : const CircleAvatar(
                                      backgroundColor:
                                          Color.fromARGB(250, 250, 250, 250),
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.grey,
                                      ),
                                    ),
                            );
                          },
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                  color: _isRideActive == false
                                      ? Colors.red
                                      : Colors.green,
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(21))),
                              child: Text(
                                _isRideActive == false ? "Offline" : "Online",
                                style: const TextStyle(color: Colors.white),
                              )),
                          IconButton(
                            icon: Icon(
                              Icons.logout_outlined,
                              color: Colors.grey[500],
                            ),
                            onPressed: () async {
                              await CurrentSession.account.deleteSession(
                                  sessionId: CurrentSession.session.$id);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => LoginPage()),
                              );
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(10),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        FloatingActionButton(
                          mini: true,
                          backgroundColor: Colors.white,
                          onPressed: () {
                            if (!_isRideActive) {
                              showSnackBar("Start you ride first");
                            } else {
                              _showReportDialog();
                            }
                          },
                          child: GestureDetector(
                            onLongPress: () {
                              _showReportList();
                            },
                            child: const Icon(
                              Icons.report_rounded,
                              color: Colors.red,
                            ),
                          ),
                        ),
                        SizedBox(
                            width: 70.0,
                            height: 70.0,
                            child: RawMaterialButton(
                              fillColor: Colors.white,
                              shape: const CircleBorder(),
                              elevation: 8.0,
                              child: _isGoButtonEnabled
                                  ? Text(
                                      _isRideActive == false ? "GO" : "END",
                                      style: const TextStyle(
                                          fontSize: 26,
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold),
                                    )
                                  : const SizedBox(
                                      height: 25,
                                      width: 25,
                                      child: CircularProgressIndicator()),
                              onPressed: () {
                                if (_isRideActive) {
                                  setState(() {
                                    _isGoButtonEnabled = false;
                                    print(_isGoButtonEnabled);
                                  });
                                  sleep(const Duration(seconds: 1));
                                  _stopRide();
                                  setState(() {
                                    _isGoButtonEnabled = true;
                                  });
                                } else {
                                  setState(() {
                                    _isGoButtonEnabled = false;
                                  });
                                  _startRide();
                                  setState(() {
                                    _isGoButtonEnabled = true;
                                  });
                                }
                              },
                            )),
                        FloatingActionButton(
                          mini: true,
                          backgroundColor: Colors.white,
                          onPressed: () {},
                          child: const Icon(
                            Icons.gps_fixed,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ]),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _stopRide();
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

  void _startRide() async {
    await location.changeSettings(
        interval: 5000, accuracy: LocationAccuracy.high);
    await database.updateDocument(
        collectionId: 'buses',
        documentId: _driverBus!.id!,
        data: {"isActive": true});
    locationSubscription =
        location.onLocationChanged.listen((LocationData locationData) {
      driverLocMarker.clear();
      driverLocMarker.add(
        Marker(
          height: 36,
          point: LatLng(locationData.latitude!, locationData.longitude!),
          builder: (ctx) => const Icon(
            Icons.circle,
            color: Colors.blueAccent,
          ),
        ),
      );

      Future result = database.updateDocument(
          collectionId: "busLoca",
          documentId: _driverBus!.locationId!,
          data: {
            "latitude": locationData.latitude,
            "longitude": locationData.longitude,
            "accuracy": locationData.accuracy,
            "altitude": locationData.altitude,
            "speed": locationData.speed,
            "speedAccuracy": locationData.speedAccuracy,
            "heading": locationData.heading,
            "time": locationData.time,
            "isMock": locationData.isMock
          });
      result.then((response) {
        setState(() {
          _isRideActive = true;
        });
        if (kDebugMode) {
          print("location updated");
        }
      }).catchError((error) {
        _stopRide();
        if (kDebugMode) {
          print(error.response);
        }
      });
    });
  }

  void _stopRide() async {
    locationSubscription?.cancel();
    await database.updateDocument(
        collectionId: 'buses',
        documentId: _driverBus!.id!,
        data: {"isActive": false});
    setState(() {
      _isRideActive = false;
    });
  }

  Future<void> _setBus() async {
    DocumentList _docList;
    Future result = database.listDocuments(
        collectionId: 'buses',
        queries: [Query.equal('driverId', CurrentSession.session.userId)]);

    await result.then((response) {
      _docList = response as DocumentList;
      _driverBus = Bus.fromJson(_docList.documents[0].data);
    }).catchError((error) {
      print(error.response);
    });
  }

  void _showReportDialog() async {
    TextEditingController? details;
    TextEditingController? time;
    bool endRide = false;
    String? incidentType;
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: ((context, setState) {
              return AlertDialog(
                title: const Text("Incedint Report"),
                actionsPadding: const EdgeInsets.all(5),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: incidentType,
                        icon: const Icon(
                          Icons.arrow_downward,
                          size: 20,
                        ),
                        //elevation: 16,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                            filled: true,
                            isDense: true,
                            hintText: "Select a Type (required)",
                            hintStyle: TextStyle(color: Colors.grey[800]),
                            fillColor: Colors.white70),
                        onChanged: (String? value) {
                          incidentType = value;
                        },
                        items: <String>["Traffic Jam", "Crash"]
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value.toString()),
                          );
                        }).toList(),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      TextFormField(
                        controller: time,
                        keyboardType: TextInputType.number,
                        onChanged: (v) {
                          time = TextEditingController(text: v);
                        },
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                            filled: true,
                            isDense: true,
                            hintStyle: TextStyle(color: Colors.grey[800]),
                            hintText: "Time Delay",
                            suffix: const Text("min(s) "),
                            fillColor: Colors.white70),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      TextFormField(
                        controller: details,
                        minLines: 1,
                        maxLines: 3,
                        keyboardType: TextInputType.multiline,
                        onChanged: (v) {
                          details = TextEditingController(text: v);
                        },
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                            filled: true,
                            isDense: true,
                            hintStyle: TextStyle(color: Colors.grey[800]),
                            hintText: "Details",
                            fillColor: Colors.white70),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Container(
                            alignment: Alignment.centerLeft,
                            child: const Text(
                              "End Ride?",
                            ),
                          ),
                          Switch(
                            value: endRide,
                            onChanged: (value) {
                              setState(() {
                                endRide = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                      style: ButtonStyle(
                          padding: MaterialStateProperty.all<EdgeInsets>(
                              EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal:
                                      MediaQuery.of(context).size.width / 12))),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Cancel",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      )),
                  TextButton(
                      style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all<Color>(Colors.orange),
                          padding: MaterialStateProperty.all<EdgeInsets>(
                              EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal:
                                      MediaQuery.of(context).size.width / 12))),
                      onPressed: () {
                        database.createDocument(
                            collectionId: "busIncidents",
                            documentId: "unique()",
                            data: {
                              "type": incidentType,
                              "details": details?.text ?? "No details provided",
                              "endRide": endRide,
                              "delayTime":
                                  time == null ? 0 : int.parse(time!.text),
                              "timeStamp": DateTime.now().toString(),
                              "busId": _driverBus!.id
                            });

                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Submit",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      )),
                ],
              );
            }),
          );
        });
  }

  void _showReportList() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder(
          future: getReporList(),
          builder: ((context, snapshot) {
            List<Widget> children;
            if (snapshot.hasData) {
              DocumentList _repDocList = snapshot.data as DocumentList;
              List<Report> _reports = reportsFromJson(_repDocList);
              children = <Widget>[
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  child: const Text(
                    "Today's Reports",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(
                  thickness: 2,
                  height: 2,
                ),
                Expanded(
                  child: ListView.builder(
                      itemCount: _reports.length,
                      itemBuilder: (context, index) {
                        return Column(
                          children: [
                            Dismissible(
                              direction: DismissDirection.endToStart,
                              key: Key(_reports[index].id!),
                              background: Container(
                                color: Colors.redAccent,
                                padding: const EdgeInsets.only(right: 15),
                                alignment: Alignment.centerRight,
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              onDismissed: (direction) {
                                setState(() {
                                  database.deleteDocument(
                                      collectionId: 'busIncidents',
                                      documentId: _reports[index].id!);
                                });
                              },
                              child: ListTile(
                                leading: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _reports[index]
                                              .timeStamp!
                                              .hour
                                              .toString() +
                                          ":" +
                                          _reports[index]
                                              .timeStamp!
                                              .minute
                                              .toString(),
                                      style: const TextStyle(fontSize: 21),
                                    ),
                                  ],
                                ),
                                title: Text(_reports[index].type!),
                                subtitle: Text(_reports[index].details!),
                                trailing: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                        color: Colors.orange,
                                        border: Border.all(
                                          color: Colors.orange,
                                        ),
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(20))),
                                    child: Text(
                                      "${_reports[index].delayTime} min(s)",
                                      style:
                                          const TextStyle(color: Colors.white),
                                    )),
                              ),
                            ),
                            const Divider(
                              height: 1,
                              color: Colors.grey,
                            )
                          ],
                        );
                      }),
                )
              ];
            } else if (snapshot.hasError) {
              children = <Widget>[
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 60,
                ),
                Container(
                  width: MediaQuery.of(context).size.width / 1.25,
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.left,
                  ),
                )
              ];
            } else {
              children = const <Widget>[
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text('Loading...'),
                )
              ];
            }

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: children,
              ),
            );
          }),
        );
      },
    );
  }

  Future getReporList() {
    Future result = database.listDocuments(
        collectionId: "busIncidents",
        queries: [Query.equal('busId', _driverBus!.id)]);
    return result;
  }

  Future _getAvatar() async {
    Avatars avatars = Avatars(CurrentSession.client);
    Future result = avatars.getInitials(background: "9e9e9e", color: "ffffff");
    return result;
  }

  void showSnackBar(String message, {VoidCallback? onPressed, String? label}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      elevation: 8,
      margin: const EdgeInsets.only(bottom: 100, right: 20, left: 20),
      backgroundColor: Colors.white,
      dismissDirection: DismissDirection.startToEnd,
      behavior: SnackBarBehavior.floating,
      content: Row(
        children: [
          const Icon(
            Icons.error_rounded,
            color: Colors.red,
          ),
          Text(
            "  $message",
            style: const TextStyle(color: Colors.black),
          )
        ],
      ),
      action: SnackBarAction(
        label: label ?? "Dismiss",
        onPressed: onPressed ?? () {},
      ),
    ));
  }

  Future<void> _loadBusStops() async {
    await _setBus();
    busStopsMarkers.clear();
    List<BusStop> busStops;
    DocumentList _docList;
    Future result = database.listDocuments(
        collectionId: 'busStops',
        queries: [Query.equal('busId', _driverBus!.id)]);

    result.then((response) {
      _docList = response as DocumentList;
      busStops = busStopFromJson(_docList);
      setState(() {
        for (var i = 0; i < busStops.length; i++) {
          print(busStops[i].name! +
              ": (" +
              busStops[i].latitude!.toString() +
              ", " +
              busStops[i].longitude!.toString());
          busStopsMarkers.add(
            Marker(
                width: 100.0,
                height: 80.0,
                point: LatLng(busStops[i].latitude!, busStops[i].longitude!),
                rotate: true,
                rotateAlignment: Alignment.bottomCenter,
                anchorPos: AnchorPos.align(AnchorAlign.top),
                builder: (ctx) => Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            margin: const EdgeInsets.only(bottom: 5),
                            decoration: const BoxDecoration(
                                color: Colors.deepPurple,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(5))),
                            child: Text(
                              busStops[i].name!,
                              style: const TextStyle(color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )),
                        const Icon(
                          TransportationIcons.bus_stop_1,
                          size: 32,
                          color: Colors.deepPurple,
                        ),
                      ],
                    )),
          );
        }
        polylines.clear();
        polylines.add(Polyline(
            points: _driverBus!.routes!,
            strokeWidth: 4,
            color: Colors.purpleAccent));
      });
    }).catchError((error) {
      if (kDebugMode) {
        print(error);
      }
    });
  }
}
/*
Container(
              height: 52,
              color: Colors.white,
              //margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                      style: ButtonStyle(
                          padding: MaterialStateProperty.all<EdgeInsets>(
                              EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal:
                                      MediaQuery.of(context).size.width / 6))),
                      onPressed: () {
                        _stopRide();
                      },
                      child: const Text(
                        "Stop",
                        style: TextStyle(fontSize: 18),
                      )),
                  const VerticalDivider(
                    indent: 10,
                    endIndent: 10,
                    color: Colors.black,
                  ),
                  TextButton(
                      style: ButtonStyle(
                          padding: MaterialStateProperty.all<EdgeInsets>(
                              EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal:
                                      MediaQuery.of(context).size.width / 6))),
                      onPressed: () {
                        _startRide();
                      },
                      child: const Text(
                        "Start",
                        style: TextStyle(fontSize: 18),
                      )),
                ],
              ),
            ),
 */