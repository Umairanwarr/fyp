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

  Stop({
    required this.stopName,
    required this.stopLocation,
    required this.time,
  });

  Stop.empty()
      : stopName = '',
        stopLocation = '',
        time = '';

  factory Stop.fromJson(Map<String, dynamic> json) {
    return Stop(
      stopName: json['stopName'],
      stopLocation: json['stopLocation'],
      time: json['time'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stopName': stopName,
      'time': time,
    };
  }
}
