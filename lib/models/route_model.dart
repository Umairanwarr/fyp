import 'package:google_maps_flutter/google_maps_flutter.dart';

class BusRouteModel {
  String id;
  String startTime;
  String driverId;
  String startLocation;
  String endLocation;
  LatLng startCords;
  LatLng endCords;
  int totalStops;
  List<Stop> stops;

  BusRouteModel({
    required this.id,
    required this.driverId,
    required this.startTime,
    required this.startLocation,
    required this.endLocation,
    required this.startCords,
    required this.endCords,
    required this.totalStops,
    required this.stops,
  });

  BusRouteModel.empty()
      : startLocation = '',
        id = '',
        startTime = '',
        driverId = '',
        endLocation = '',
        startCords = LatLng(0, 0),
        endCords = LatLng(0, 0),
        totalStops = 0,
        stops = [];

  factory BusRouteModel.fromJson(Map<String, dynamic> json) {
    return BusRouteModel(
      id: json['id'],
      startTime: json['startTime'],
      startLocation: json['startLocation'],
      driverId: json['driverId'],
      endLocation: json['endLocation'],
      startCords: _latLngFromJson(json['startCords']),
      endCords: _latLngFromJson(json['endCords']),
      totalStops: json['totalStops'],
      stops: (json['stops'] as List<dynamic>).map((i) => Stop.fromJson(i)).toList(),
    );
  }

  factory BusRouteModel.fromFirestore(Map<String, dynamic> data, String id) {
    return BusRouteModel(
      id: id, // use id parameter, not data['id']
      startTime: data['startTime'],
      startLocation: data['startLocation'],
      driverId: data['driverId'],
      endLocation: data['endLocation'],
      startCords: _latLngFromJson(data['startCords']),
      endCords: _latLngFromJson(data['endCords']),
      totalStops: data['totalStops'],
      stops: (data['stops'] as List<dynamic>).map((stop) => Stop.fromJson(stop)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startLocation': startLocation,
      'startTime': startTime,
      'driverId': driverId,
      'endLocation': endLocation,
      'startCords': _latLngToJson(startCords),
      'endCords': _latLngToJson(endCords),
      'totalStops': totalStops,
      'stops': stops.map((stop) => stop.toJson()).toList(),
    };
  }

  static LatLng _latLngFromJson(Map<String, dynamic> json) {
    return LatLng(json['latitude'], json['longitude']);
  }

  static Map<String, dynamic> _latLngToJson(LatLng latLng) {
    return {'latitude': latLng.latitude, 'longitude': latLng.longitude};
  }
}


class Stop {
  String stopName;
  String stopLocation;
  String time;
  LatLng stopCords;
  bool isReached = false;

  Stop({
    required this.stopName,
    required this.stopLocation,
    required this.time,
    required this.isReached,
    required this.stopCords,
  });

  Stop.empty()
      : stopName = '',
        stopLocation = '',
        time = '',
        isReached = false,
        stopCords = LatLng(0, 0);

  factory Stop.fromJson(Map<String, dynamic> json) {
    return Stop(
      stopName: json['stopName'],
      stopLocation: json['stopLocation'],
      time: json['time'],
      isReached: json['isReached'],
      stopCords: BusRouteModel._latLngFromJson(json['stopCords']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stopName': stopName,
      'stopLocation': stopLocation,
      'time': time,
      'isReached': isReached,
      'stopCords': BusRouteModel._latLngToJson(stopCords),
    };
  }
}
