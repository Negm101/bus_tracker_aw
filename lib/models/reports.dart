import 'dart:convert';

import 'package:appwrite/models.dart';

Report reportFromJson(String str) => Report.fromJson(json.decode(str));
List<Report> reportsFromJson(DocumentList _list) =>
    _list.documents.map((e) => Report.fromJson(e.data)).toList();
String reportToJson(Report data) => json.encode(data.toJson());

class Report {
  Report({
    this.delayTime,
    this.details,
    this.type,
    this.endRide,
    this.read,
    this.write,
    this.id,
    this.collection,
    this.timeStamp,
    this.busId,
  });

  int? delayTime;
  String? details;
  String? type;
  bool? endRide;
  DateTime? timeStamp;
  String? busId;
  List<dynamic>? read;
  List<String>? write;
  String? id;
  String? collection;

  factory Report.fromJson(Map<String, dynamic> json) => Report(
        delayTime: json["delayTime"],
        details: json["details"],
        type: json["type"],
        endRide: json["endRide"],
        busId: json["busId"],
        timeStamp: DateTime.parse(json["timeStamp"]),
        read: json["\u0024read"] == null
            ? null
            : List<dynamic>.from(json["\u0024read"].map((x) => x)),
        write: json["\u0024write"] == null
            ? null
            : List<String>.from(json["\u0024write"].map((x) => x)),
        id: json["\u0024id"],
        collection: json["\u0024collection"],
      );

  Map<dynamic, dynamic> toJson() => {
        "delayTime": delayTime,
        "details": details,
        "type": type,
        "endRide": endRide,
        "\u0024read":
            read == null ? "" : List<dynamic>.from(read!.map((x) => x)),
        "\u0024write":
            write == null ? "" : List<dynamic>.from(write!.map((x) => x)),
        "\u0024id": id,
        "\u0024collection": collection,
      };
}
