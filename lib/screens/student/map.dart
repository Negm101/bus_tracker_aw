import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:bus_tracker_aw/helpers/eta.dart';
import 'package:bus_tracker_aw/models/bus-location.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:badges/badges.dart';

import '../../general.dart';
import '../../helpers/transportation_icons_icons.dart';
import '../../models/bus-stops.dart';
import '../../models/reports.dart';
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
  List<Polyline> polylines = [];
  late bool _serviceEnabled;
  late PermissionStatus _permissionGranted;
  StreamSubscription<LocationData>? locationSubscription;
  late Database _database;
  List<Bus>? buses;
  List<DropdownMenuItem<String>>? busesId;
  // Bus Stops
  // Current Bus
  LatLng _busLocation = LatLng(2.9252, 101.6376);
  Bus? _selectedBus;
  // Realtime location
  Realtime? _realtime;
  RealtimeSubscription? _subscription;
  BusLocation? _locationReal;
  // Incident Report Subscribtion
  Realtime? _reportRealtime;
  RealtimeSubscription? _realTimeSubRep;
  // Bus Stops
  List<BusStop>? busStops;
  List<Marker> allbusStopsMarkers = [];

  bool isThereIncident = false;
  int incidentNo = 0;

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
    return Scaffold(
        body: SafeArea(
      child: Stack(
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
              PolylineLayerOptions(polylines: polylines),
              MarkerLayerOptions(
                markers: allbusStopsMarkers,
              ),
              CircleLayerOptions(circles: userLocationLayer),
              MarkerLayerOptions(markers: busLocationMarker)
            ],
          ),
          Container(
            margin: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
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
                          icon: IconButton(
                            icon: const Icon(
                              Icons.info_rounded,
                              color: Colors.grey,
                              size: 18,
                            ),
                            onPressed: () {
                              showBusDetails();
                            },
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    incidentNo > 0
                        ? Badge(
                            animationType: BadgeAnimationType.scale,
                            badgeContent: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Text(
                                incidentNo.toString(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                            ),
                            child: FloatingActionButton(
                              child: const Icon(
                                Icons.notifications,
                                color: Colors.orange,
                              ),
                              backgroundColor: Colors.white,
                              onPressed: () {
                                if (kDebugMode) {
                                  print(myLocation);
                                }
                                _showReportList();
                              },
                            ),
                          )
                        : FloatingActionButton(
                            child: const Icon(
                              Icons.notifications,
                              color: Colors.orange,
                            ),
                            backgroundColor: Colors.white,
                            onPressed: () {
                              if (kDebugMode) {
                                print(myLocation);
                              }
                              _showReportList();
                            },
                          ),
                    FloatingActionButton(
                      backgroundColor: Colors.white,
                      onPressed: () {
                        if (kDebugMode) {
                          print(myLocation);
                        }
                        _mapController.move(myLocation, 15);
                      },
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  @override
  void dispose() {
    locationSubscription?.cancel();
    _subscription?.close();
    _realTimeSubRep?.close();
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
            builder: (ctx) => const Icon(
              Icons.location_on,
              color: Colors.redAccent,
            ),
          ),
        );
      });
    });
    loadBusStops();
    subToReports();
  }

  void showBusDetails() {
    ETA _eta = ETA(routePoints: _selectedBus!.routes!);
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
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                    Tab(
                      child: Text(
                        "Stations",
                        style: TextStyle(color: Colors.black54),
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
                          trailing: Text(_selectedBus!.plateNumber!),
                        ),
                        ListTile(
                          title: const Text("Color"),
                          trailing: Text(_selectedBus!.busColor!),
                        ),
                        ListTile(
                          title: const Text("City"),
                          trailing: Text(_selectedBus!.city!),
                        ),
                        ListTile(
                          title: const Text("Total Distance"),
                          trailing: Text("${_eta.getDistance()} KMs"),
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
                              title: Text(busStops![index].name!),
                              trailing: IconButton(
                                icon: const Icon(Icons.directions_walk),
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
                width: 100.0,
                height: 80.0,
                point: LatLng(busStops![i].latitude!, busStops![i].longitude!),
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
                              "(${busStops![i].order}) ${busStops![i].name!}",
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
            points: _selectedBus!.routes!,
            strokeWidth: 4,
            color: Colors.purpleAccent));
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

    var _locationData = await location.getLocation();
  }

  void _showReportList() {
    setState(() {
      isThereIncident = false;
    });
    if (_selectedBus != null) {
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
                if (_repDocList.documents.isNotEmpty) {
                  print("has data");
                  children = <Widget>[
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      child: const Text(
                        "Today's Reports",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 21, fontWeight: FontWeight.bold),
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
                                ListTile(
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
                                        style: const TextStyle(
                                            color: Colors.white),
                                      )),
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
                } else {
                  print("has no data");
                  children = <Widget>[
                    SvgPicture.asset(
                      'assets/svgs/time.svg',
                      width: MediaQuery.of(context).size.width / 3,
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 30),
                      child: const Text(
                        "The bus should \nbe on time",
                        style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey),
                        textAlign: TextAlign.center,
                      ),
                    )
                  ];
                }
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
    } else {}
  }

  Future getReporList() {
    Future result = _database.listDocuments(
        collectionId: "busIncidents",
        queries: [Query.equal('busId', _selectedBus!.id)]);
    return result;
  }

  Future<void> setIncNo() async {
    await _database.listDocuments(
        collectionId: "busIncidents",
        queries: [Query.equal('busId', _selectedBus!.id)]).then((value) {
      setState(() {
        incidentNo = value.total;
      });
    });
  }

  Future<void> subToReports() async {
    setIncNo();
    _realTimeSubRep =
        _realtime!.subscribe(['collections.busIncidents.documents']);
    _realTimeSubRep?.stream.listen((event) {
      setIncNo();
    });
  }
}
