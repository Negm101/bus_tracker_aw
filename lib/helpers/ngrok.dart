import 'dart:convert';
import 'dart:io';

import 'package:bus_tracker_aw/models/ngrokEndpoint.dart';
import 'package:http/http.dart' as http;

class NgRok {
  NgRok({required this.apikey});
  final String apikey;
  Future<NgRokEndpoint> listEnpoints() async {
    final response = await http.get(
      Uri.parse("https://api.ngrok.com/endpoints"),
      headers: {
        "Authorization": "Bearer $apikey",
        "Content-Type": "application/json;charset=utf-8",
        "Ngrok-Version": "2",
      },
    );
    if (response.statusCode == 200) {
      return ngRokEndpointFromJson(response.body);
    } else {
      throw Exception('Failed to load movies');
    }
  }
}
