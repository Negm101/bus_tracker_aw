// To parse this JSON data, do
//
//     final Bus = BusFromJson(jsonString);

import 'dart:convert';

import 'package:appwrite/models.dart';
import 'package:latlong2/latlong.dart';

Bus busFromJson(String str) => Bus.fromJson(json.decode(str));
List<Bus> busesfromJson(DocumentList _list) =>
    _list.documents.map((e) => Bus.fromJson(e.data)).toList();
String busToJson(Bus data) => json.encode(data.toJson());

class Bus {
  Bus({
    this.driverId,
    this.locationId,
    this.isActive,
    this.plateNumber,
    this.busColor,
    this.routes,
    this.city,
    this.id,
    this.collection,
    List<String>? busStops,
  });

  String? driverId;
  String? locationId;
  bool? isActive;
  String? plateNumber;
  String? busColor;
  List<LatLng>? routes;
  String? city;
  String? id;
  String? collection;
  List<String>? busStops;

  factory Bus.fromJson(Map<String, dynamic> json) { 
    List<LatLng> latLngs = [];
    for (int i = 0; i < json["routes"].length; i++) {
      latLngs.add(LatLng(
          double.parse(json["routes"][i].replaceAll("\"", "").split(',')[0]),
          double.parse(json["routes"][i].replaceAll("\"", "").split(',')[1])));
    }
    return Bus(
        driverId: json["driverId"],
        locationId: json["locationId"],
        isActive: json["isActive"],
        plateNumber: json["plateNumber"],
        busColor: json["busColor"],
        routes: latLngs,
        city: json['city'],
        busStops: List<String>.from(json["busStops"].map((x) => x)),
        id: json["\u0024id"],
        collection: json["\u0024collection"],
      );}

  Map<String, dynamic> toJson() => {
        "driverId": driverId,
        "locationId": locationId,
        "isActive": isActive,
        "plateNumber": plateNumber,
        "busStops": busStops == null
            ? null
            : List<dynamic>.from(busStops!.map((x) => x)),
        "\u0024id": id,
        "\u0024collection": collection,
      };
}

LocationReal locaFromJson(String str) =>
    LocationReal.fromJson(json.decode(str));

class LocationReal {
  LocationReal({
    this.latitude,
    this.longitude,
  });

  double? latitude;
  double? longitude;

  factory LocationReal.fromJson(Map<String, dynamic> json) => LocationReal(
        latitude: json['latitude'] == null ? "0" : json["latitude"].toDouble(),
        longitude:
            json['longitude'] == null ? "0" : json["longitude"].toDouble(),
      );
}
