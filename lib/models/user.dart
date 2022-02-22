// To parse this JSON data, do
//
//     final Bus = BusFromJson(jsonString);

import 'dart:convert';

import 'package:appwrite/models.dart';

Bus busFromJson(String str) => Bus.fromJson(json.decode(str));
List<Bus> busesfromJson(DocumentList _list) =>
    _list.documents.map((e) => Bus.fromJson(e.data)).toList();
String busToJson(Bus data) => json.encode(data.toJson());

class Bus {
  Bus({
    this.driverName,
    this.plateNumber,
    this.latitude,
    this.longitude,
    this.isActive,
    this.id,
    this.internalId,
    this.read,
    this.write,
    this.collection,
  });

  String? driverName;
  String? plateNumber;
  double? latitude;
  double? longitude;
  bool? isActive;
  String? id;
  String? internalId;
  List<String>? read;
  List<String>? write;
  String? collection;

  factory Bus.fromJson(Map<String, dynamic> json) => Bus(
        driverName: json["driverName"],
        plateNumber: json["plateNumber"],
        latitude: json["latitude"].toDouble(),
        longitude: json["longitude"].toDouble(),
        isActive: json["isActive"],
        id: json["\u0024id"],
        internalId: json["\u0024internalId"],
        read: List<String>.from(json["\u0024read"].map((x) => x)),
        write: List<String>.from(json["\u0024write"].map((x) => x)),
        collection: json["\u0024collection"],
      );

  Map<String, dynamic> toJson() => {
        "driverName": driverName,
        "plateNumber": plateNumber,
        "latitude": latitude,
        "longitude": longitude,
        "isActive": isActive,
        "\u0024id": id,
        "\u0024internalId": internalId,
        //"\u0024read": List<String>.from(read?.map((x) => x)),
        //"\u0024write": List<String>.from(write.map((x) => x)),
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
