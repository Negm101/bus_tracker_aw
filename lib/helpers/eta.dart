import 'dart:math';

import 'package:latlong2/latlong.dart';

class ETA {
  final double pi = 3.1415926535897932;
  ETA({required this.routePoints});
  List<LatLng> routePoints;

  double _distance(double lat1, double lat2, double lon1, double lon2) {
    lon1 = _toRadian(lon1);
    lon2 = _toRadian(lon2);
    lat1 = _toRadian(lat1);
    lat2 = _toRadian(lat2);

    double dlon = lon2 - lon1;
    double dlat = lat2 - lat1;
    double a =
        pow(sin(dlat / 2), 2) + cos(lat1) * cos(lat2) * pow(sin(dlon / 2), 2);

    double c = 2 * asin(sqrt(a));
    double r = 6371;
    
    return (c * r);
  }

  double _toRadian(double degree) {
    return degree * pi / 100;
  }

  double getDistance() {
    double _finalDistance = 0;
    for (int i = 0; i < routePoints.length - 1; i++) {
      double _dis = _distance(
          routePoints[i].latitude,
          routePoints[i + 1].latitude,
          routePoints[i + 1].longitude,
          routePoints[i + 1].longitude);
      _finalDistance = _finalDistance + _dis;
      //print(_dis);
    }
    return _finalDistance;
  }
}
