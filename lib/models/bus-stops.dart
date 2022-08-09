import 'dart:convert';

import 'package:appwrite/models.dart';

List<BusStop> busStopFromJson(DocumentList _list) =>
    _list.documents.map((e) => BusStop.fromJson(e.data)).toList();

class BusStop {
  BusStop({
    this.name,
    this.longitude,
    this.latitude,
    this.order,
    this.busId,
    this.id,
    this.collection,
  });

  String? name;
  double? longitude;
  double? latitude;
  int? order;
  String? busId;
  String? id;
  String? collection;

  factory BusStop.fromJson(Map<String, dynamic> json) => BusStop(
        name: json["name"],
        longitude:
            json["longitude"] == null ? null : double.parse(json["longitude"]),
        latitude:
            json["latitude"] == null ? null : double.parse(json["latitude"]),
        order: json["orderByNav"],
        busId: json["busId"],
        id: json["\u0024id"],
        collection: json["\u0024collection"],
      );
}
