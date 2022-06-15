import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:bus_tracker_aw/models/bus-location.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:map_controller/map_controller.dart';

import '../../general.dart';
import '../../models/bus-stops.dart';
import '../../models/user.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  LatLng mapCenter = LatLng(2.9252, 101.6376);
  late MapController _mapController;
  LatLng myLocation = LatLng(2.9252, 101.6376);

  List<Marker> busStopsMarkers = [];
  Location location = Location();
  List<CircleMarker> userLocationLayer = [];
  List<Marker> busLocationMarker = [];
  late bool _serviceEnabled;
  late PermissionStatus _permissionGranted;
  LocationData? _locationData;
  StreamSubscription<LocationData>? locationSubscription;
  late Database _database;
  List<Bus>? buses;
  List<DropdownMenuItem<String>>? busesId;
  // Bus Stops
  StatefulMapController? statefulMapController;
  // Current Bus
  LatLng _busLocation = LatLng(2.9252, 101.6376);
  Bus? _selectedBus;
  // Realtime location
  Realtime? _realtime;
  RealtimeSubscription? _subscription;
  BusLocation? _locationReal;
  // Bus Stops
  List<BusStop>? busStops;
  List<Marker> allbusStopsMarkers = [];

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    _database = Database(CurrentSession.client);
    location.enableBackgroundMode(enable: false);
    locationSubscription =
        location.onLocationChanged.listen((LocationData locationData) {
      setState(() {
        myLocation = LatLng(locationData.latitude!, locationData.longitude!);
        userLocationLayer.clear();
        userLocationLayer.add(CircleMarker(
            point: myLocation,
            radius: 8,
            borderStrokeWidth: 2,
            color: Colors.lightBlueAccent,
            borderColor: Colors.blue));
      });
    });
    _setBuses();
    _mapController = MapController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            floatingActionButton: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: () {
                if (kDebugMode) {
                  print(myLocation);
                }
                _mapController.move(myLocation, 15);
              },
              child: const Icon(
                Icons.my_location,
                color: Colors.orange,
              ),
            ),
            body: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                      center: mapCenter,
                      swPanBoundary: myLocation,
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
                      markers: allbusStopsMarkers,
                    ),
                    CircleLayerOptions(circles: userLocationLayer),
                    MarkerLayerOptions(markers: busLocationMarker)
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(
                      left: 20, right: 20, bottom: 20, top: 20),
                  width: double.infinity,
                  padding: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      color: Colors.white,
                      border: Border.all()),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                          onPressed: () {
                            setState(() {
                              clearMap();
                              _setBuses();
                            });
                          },
                          icon: const Icon(
                            Icons.refresh_rounded,
                            size: 20,
                          )),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton(
                              hint: const Text("Select Bus"),
                              value: _selectedBus,
                              borderRadius: BorderRadius.circular(10),
                              items: buses
                                  ?.map<DropdownMenuItem<Bus>>((Bus value) {
                                return DropdownMenuItem<Bus>(
                                  value: value,
                                  child: Row(
                                    children: [
                                      value.isActive == true
                                          ? const Icon(
                                              Icons.circle,
                                              color: Colors.greenAccent,
                                              size: 16,
                                            )
                                          : const Icon(
                                              Icons.circle,
                                              color: Colors.redAccent,
                                              size: 16,
                                            ),
                                      Text(" " + value.plateNumber!)
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedBus = value as Bus?;
                                });
                                subToBus();
                              }),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )));
  }

  @override
  void dispose() {
    locationSubscription?.cancel();
    _subscription?.close();
    super.dispose();
  }

  void _setBuses() async {
    DocumentList _docList;

    Future result = _database.listDocuments(
      collectionId: 'buses',
    );

    await result.then((response) {
      _docList = response as DocumentList;
      setState(() {
        buses = busesfromJson(_docList);
      });
    }).catchError((error) {
      if (kDebugMode) {
        print(error);
      }
    });
  }

  void subToBus() async {
    _subscription?.close();
    allbusStopsMarkers.clear();
    busLocationMarker.clear();
    _realtime = Realtime(CurrentSession.client);
    _subscription = _realtime!.subscribe(
        ['collections.busLoca.documents.${_selectedBus!.locationId}']);
    _subscription?.stream.listen((response) {
      print("location updated");
      _locationReal = BusLocation.fromJson(response.payload);
      setState(() {
        busLocationMarker.clear();
        _busLocation =
            LatLng(_locationReal!.latitude!, _locationReal!.longitude!);
        busLocationMarker.add(
          Marker(
              width: 80.0,
              height: 80.0,
              point: _busLocation,
              builder: (ctx) => IconButton(
                    icon: const Icon(
                      Icons.location_on,
                      color: Colors.redAccent,
                    ),
                    onPressed: () {
                      if (_selectedBus != null) {
                        showModalBottomSheet<void>(
                          context: context,
                          builder: (BuildContext context) {
                            return DefaultTabController(
                              length: 2,
                              child: Scaffold(
                                appBar: AppBar(
                                  automaticallyImplyLeading: false,
                                  leading: const Icon(
                                    Icons.crop_square_rounded,
                                    size: 32,
                                    color: Colors.black54,
                                  ),
                                  backgroundColor: Colors.white,
                                  bottom: const TabBar(
                                    tabs: [
                                      Tab(
                                        child: Text(
                                          "Details",
                                          style:
                                              TextStyle(color: Colors.black54),
                                        ),
                                      ),
                                      Tab(
                                        child: Text(
                                          "Stations",
                                          style:
                                              TextStyle(color: Colors.black54),
                                        ),
                                      ),
                                    ],
                                  ),
                                  title: Text(
                                    _selectedBus!.plateNumber!,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        color: Colors.black54,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  actions: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        color: Colors.black54,
                                        size: 32,
                                      ),
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ],
                                ),
                                body: TabBarView(
                                  children: [
                                    Container(
                                      child: Column(
                                        children: [
                                          const Divider(
                                            height: 0,
                                            thickness: 1,
                                          ),
                                          ListTile(
                                            title: const Text("Plate Number"),
                                            trailing: Text(
                                                _selectedBus!.plateNumber!),
                                          ),
                                          ListTile(
                                            title: const Text("Color"),
                                            trailing:
                                                Text(_selectedBus!.busColor!),
                                          ),
                                          ListTile(
                                            title: const Text("City"),
                                            trailing: Text(_selectedBus!.city!),
                                          )
                                        ],
                                      ),
                                    ),
                                    Container(
                                      child: ListView.builder(
                                          itemCount: busStops?.length,
                                          itemBuilder: (context, index) {
                                            return ListTile(
                                                leading: const Icon(
                                                  Icons.circle,
                                                ),
                                                title: Text(
                                                    busStops![index].name!),
                                                trailing: IconButton(
                                                  icon: const Icon(
                                                      Icons.directions_walk),
                                                  onPressed: () {
                                                    /*navigateTo(
                                                                      busStops![
                                                                              index]
                                                                          .latitude!,
                                                                      busStops![
                                                                              index]
                                                                          .longitude!);*/
                                                  },
                                                ));
                                          }),
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }
                    },
                  )),
        );
      });
    });
    loadBusStops();
  }

  void loadBusStops() {
    print("selecting bus stops for:  ${_selectedBus!.id}");
    DocumentList _docList;
    _database = Database(CurrentSession.client);
    Future result = _database.listDocuments(
        collectionId: 'busStops',
        queries: [Query.equal('busId', _selectedBus!.id)]);

    result.then((response) {
      _docList = response as DocumentList;
      busStops = busStopFromJson(_docList);
      setState(() {
        for (var i = 0; i < busStops!.length; i++) {
          allbusStopsMarkers.add(
            Marker(
                width: 80.0,
                height: 80.0,
                point: LatLng(busStops![i].latitude!, busStops![i].longitude!),
                builder: (ctx) => const Icon(
                      Icons.pin_drop_rounded,
                      color: Colors.blueAccent,
                      //size: 32,
                    )),
          );
        }
      });
    }).catchError((error) {
      if (kDebugMode) {
        print(error);
      }
    });
  }

  static void navigateTo(double lat, double lng) async {
    var uri =
        Uri.parse("https://www.google.com/maps/search/?api=1&query=$lng,$lat");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch ${uri.toString()}';
    }
  }

  void clearMap() {
    _subscription?.close();
    allbusStopsMarkers.clear();
    busLocationMarker.clear();
    buses = null;
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
