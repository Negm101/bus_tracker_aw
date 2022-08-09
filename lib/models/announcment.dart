import 'dart:convert';

import 'package:appwrite/models.dart';


List<Announcement> announcementsFromJson(DocumentList _list) =>
    _list.documents.map((e) => Announcement.fromJson(e.data)).toList();

class Announcement {
  Announcement({
    this.title,
    this.body,
    this.bodyDelta,
    this.imageLink,
    this.dateCreated,
    this.id,
    this.collection,
  });

  String? title;
  String? body;
  String? bodyDelta;
  String? imageLink;
  DateTime? dateCreated;
  String? id;
  String? collection;

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        title: json["title"],
        body: json["body"],
        bodyDelta: json["bodyDelta"],
        imageLink: json["imageLink"],
        dateCreated: json["dateCreated"] == null
            ? null
            : DateTime.parse(json["dateCreated"]),
        id: json["\u0024id"],
        collection: json["\u0024collection"],
      );
}

