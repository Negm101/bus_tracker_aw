// To parse this JSON data, do
//
//     final busLocation = busLocationFromJson(jsonString);

import 'dart:convert';

BusLocation busLocationFromJson(String str) =>
    BusLocation.fromJson(json.decode(str));

String busLocationToJson(BusLocation data) => json.encode(data.toJson());

class BusLocation {
  BusLocation({
    this.latitude,
    this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    this.speedAccuracy,
    this.heading,
    this.time,
    this.isMock,
    this.busId,
    this.id,
    this.collection,
  });

  double? latitude;
  double? longitude;
  double? accuracy;
  double? altitude;
  double? speed;
  double? speedAccuracy;
  double? heading;
  double? time;
  bool? isMock;
  String? busId;
  String? id;
  String? collection;

  factory BusLocation.fromJson(Map<String, dynamic> json) => BusLocation(
        latitude: json["latitude"].toDouble(),
        longitude: json["longitude"].toDouble(),
        accuracy: json["accuracy"].toDouble(),
        altitude: json["altitude"].toDouble(),
        speed: json["speed"].toDouble(),
        speedAccuracy: json["speedAccuracy"],
        heading: json["heading"].toDouble(),
        time: json["time"].toDouble(),
        isMock: json["isMock"],
        busId: json["busId"],
        id: json["\u0024id"],
        collection: json["\u0024collection"],
      );

  Map<String, dynamic> toJson() => {
        "latitude": latitude,
        "longitude": longitude,
        "accuracy": accuracy,
        "altitude": altitude,
        "speed": speed,
        "speedAccuracy": speedAccuracy,
        "heading": heading,
        "time": time,
        "isMock": isMock,
      };
}
