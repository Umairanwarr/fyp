import 'package:cloud_firestore/cloud_firestore.dart';

class BusRouteModel {

  String startLocation;
  String endLocation;
  int totalStops;
  List<Stop> stops;

  BusRouteModel({
    required this.startLocation,
    required this.endLocation,
    required this.totalStops,
    required this.stops,
  });

  BusRouteModel.empty()
      : startLocation = '',
        endLocation = '',
        totalStops = 0,
        stops = [];

  factory BusRouteModel.fromJson(Map<String, dynamic> json) {
    return BusRouteModel(
      startLocation: json['startLocation'],
      endLocation: json['endLocation'],
      totalStops: json['totalStops'],
      stops: (json['stops'] as List).map((i) => Stop.fromJson(i)).toList(),
    );
  }

  factory BusRouteModel.fromFirestore(Map<String, dynamic> data, String id) {
    return BusRouteModel(
      startLocation: data['startLocation'],
      endLocation: data['endLocation'],
      totalStops: data['totalStops'],
      stops: (data['stops'] as List).map((i) => Stop.fromJson(i)).toList(),
    );
  }



  Map<String, dynamic> toJson() {
    return {
      'startLocation': startLocation,
      'endLocation': endLocation,
      'totalStops': totalStops,
      'stops': stops.map((stop) => stop.toJson()).toList(),
    };
  }
}

class Stop {
  String stopName;
  String stopLocation;
  String time;
  bool isReached = false;

  Stop({
    required this.stopName,
    required this.stopLocation,
    required this.time,
    required this.isReached,
  });

  Stop.empty()
      : stopName = '',
        stopLocation = '',
        time = '',
        isReached = false;

  factory Stop.fromJson(Map<String, dynamic> json) {
    return Stop(
      stopName: json['stopName'],
      stopLocation: json['stopLocation'],
      time: json['time'],
      isReached: json['isReached'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stopName': stopName,
      'stopLocation': stopLocation,
      'time': time,
      'isReached':isReached,
    };
  }
}
