import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:map_controller/map_controller.dart';

import '../../general.dart';
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

  List<Marker> markers = [];
  Location location = Location();

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
  LocationReal? _locationReal;

  @override
  void initState() {
    //loadData();
    location.enableBackgroundMode(enable: false);
    locationSubscription =
        location.onLocationChanged.listen((LocationData locationData) {
      setState(() {
        myLocation = LatLng(locationData.latitude!, locationData.longitude!);
      });
    });

    DocumentList _docList;
    _database = Database(CurrentSession.client);
    Future result = _database.listDocuments(
      collectionId: 'buss',
    );

    result.then((response) {
      _docList = response as DocumentList;
      buses = busesfromJson(_docList);
      print(busesId.toString());
    }).catchError((error) {
      print(error);
    });

    _mapController = MapController();
    //statefulMapController = StatefulMapController(mapController: _mapController);
    //statefulMapController?.onReady.then((_) => loadData());
    //statefulMapController?.changeFeed.listen((change) => setState(() {}));
    //print(statefulMapController?.lines.toString());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.my_location),
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
                    //MarkerLayerOptions(markers: statefulMapController!.markers),
                    MarkerLayerOptions(
                      markers: [
                        Marker(
                            width: 80.0,
                            height: 80.0,
                            point: myLocation,
                            builder: (ctx) => const Icon(
                                  Icons.circle,
                                  color: Colors.lightBlueAccent,
                                  //size: 32,
                                )),
                        Marker(
                            width: 80.0,
                            height: 80.0,
                            point: _busLocation,
                            builder: (ctx) => const Icon(
                                  Icons.location_on,
                                  color: Colors.redAccent,
                                  //size: 32,
                                )),
                      ],
                    ),
                  ],
                ),
                Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(
                      left: 20, right: 20, bottom: 20, top: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        color: Colors.white,
                        border: Border.all()),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton(
                          hint: const Text("Select Bus"),
                          value: _selectedBus,
                          items: buses?.map<DropdownMenuItem<Bus>>((Bus value) {
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
                ),
              ],
            )));
  }

  @override
  void dispose() {
    locationSubscription?.cancel();
    super.dispose();
  }

  void loadData() async {
    print("Loading geojson data");
    final data = await rootBundle.loadString('assets/cyberjaya-1.geojson');
    await statefulMapController?.fromGeoJson(data,
        markerIcon: Icon(Icons.local_airport), verbose: true);
  }

  void subToBus() {
    _realtime = Realtime(CurrentSession.client);
    _subscription = _realtime!.subscribe(['collections.buss.documents.${_selectedBus!.id}']);
    _subscription?.stream.listen((response) {
      _locationReal = LocationReal.fromJson(response.payload);
      _busLocation =
          LatLng(_locationReal!.latitude!, _locationReal!.longitude!);
      print("location: " + _busLocation.toString());
    });
    print("selected bus id" + _selectedBus!.id.toString());
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
