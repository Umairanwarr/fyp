// ignore_for_file: must_be_immutable

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:first_bus_project/models/route_model.dart';
import 'package:first_bus_project/models/user_model.dart';
import 'package:first_bus_project/services/routes_services.dart';
import 'package:first_bus_project/student/home/student_nearest_stop.dart';
import 'package:first_bus_project/student/menu/student_menu.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class StudentMapScreen extends StatefulWidget {
  UserModel userModel;
  StudentMapScreen({super.key, required this.userModel});

  @override
  State<StudentMapScreen> createState() => _StudentMapScreenState();
}

class _StudentMapScreenState extends State<StudentMapScreen> {
  GoogleMapController? mapController;
  LatLng? currentLocation;
  Map<String, List<LatLng>> allCords = {};
  Set<Marker> stopMarkers = {};
  String? selectedRouteId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RoutesService _routesService = RoutesService();

  @override
  void initState() {
    super.initState();
    getBuses();
    _getCurrentLocation();
  }

  Future<void> getBuses() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('busRoutes').get();

      setState(() {
        querySnapshot.docs.forEach((doc) {
          BusRouteModel bus = BusRouteModel.fromFirestore(
              doc.data() as Map<String, dynamic>, doc.id);
          List<LatLng> busCords = [bus.startCords];
          bus.stops.forEach((stop) => busCords.add(stop.stopCords));
          busCords.add(bus.endCords);
          allCords[bus.id] = busCords;
        });
      });
    } catch (e) {
      print("Error fetching buses: $e");
    }
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      currentLocation = LatLng(position.latitude, position.longitude);
    });
  }

  void _onFabPressed() async {
    await _getCurrentLocation();
    mapController?.animateCamera(CameraUpdate.newLatLngZoom(currentLocation!, 13));
  }

  Set<Polyline> _createPolylines() {
    Set<Polyline> polylines = {};
    allCords.forEach((docId, coordinates) {
      if (coordinates.isNotEmpty) {
        Color color = (selectedRouteId == docId)
            ? Colors.blueAccent
            : Colors.grey.withOpacity(0.6);
        polylines.add(Polyline(
          polylineId: PolylineId(docId),
          color: color,
          width: 5,
          points: coordinates,
        ));
      }
    });
    return polylines;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Comsats Wah Routes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("All station routing on Comsats Wah", style: TextStyle(fontSize: 16)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => StudentMenuScreen(userModel: widget.userModel)),
              );
            },
            icon: Icon(Icons.person),
          ),
        ],
      ),
      body: SlidingUpPanel(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
        minHeight: MediaQuery.of(context).size.height * 0.4,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        panel: _buildRouteList(),
        body: GoogleMap(
          onMapCreated: (GoogleMapController controller) {
            setState(() {
              mapController = controller;
            });
            if (currentLocation != null) {
              mapController?.animateCamera(CameraUpdate.newLatLngZoom(currentLocation!, 11));
            }
          },
          polylines: _createPolylines(),
          markers: stopMarkers,
          initialCameraPosition: CameraPosition(
            target: currentLocation ?? LatLng(33.7445, 72.7867),
            zoom: 12,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onFabPressed,
        child: Icon(Icons.my_location),
      ),
    );
  }

 Widget _buildRouteList() {
  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: _firestore.collection('busRoutes').snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
      if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

      // Convert Firestore documents to BusRouteModel
      List<BusRouteModel> busRoutes = snapshot.data!.docs
          .map((doc) => BusRouteModel.fromFirestore(doc.data(), doc.id))
          .toList();

      // Create a list of Future distances for each route
      List<Future<Map<String, dynamic>>> distanceFutures = busRoutes.map((route) async {
        double distance = await calculateDistanceFromCurrentLocation(route.startCords.latitude, route.startCords.longitude);
        return {'route': route, 'distance': distance};
      }).toList();

      return FutureBuilder<List<Map<String, dynamic>>>(
        future: Future.wait(distanceFutures), // Wait for all distance calculations to complete
        builder: (context, distanceSnapshot) {
          if (distanceSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator()); // Show loading while distances are being calculated
          } else if (distanceSnapshot.hasError) {
            return Center(child: Text("Error: ${distanceSnapshot.error}"));
          } else if (distanceSnapshot.hasData) {
            // Sort routes based on distance
            List<Map<String, dynamic>> sortedRoutes = distanceSnapshot.data!;
            sortedRoutes.sort((a, b) => a['distance'].compareTo(b['distance']));

            // Rebuild the busRoutes list based on sorted distances
List<BusRouteModel> sortedBusRoutes = sortedRoutes.map((item) => item['route'] as BusRouteModel).toList();

            return ListView.builder(
              itemCount: sortedBusRoutes.length,
              itemBuilder: (context, index) {
                BusRouteModel route = sortedBusRoutes[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedRouteId = route.id;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(10),
                    margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    decoration: BoxDecoration(
                      color: selectedRouteId == route.id
                          ? Colors.blueAccent.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(route.startLocation, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("Time: ${route.startTime}", style: TextStyle(fontSize: 16)),
                        FutureBuilder<double>(
                          future: calculateDistanceFromCurrentLocation(route.startCords.latitude, route.startCords.longitude),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Container(); // Show a loading spinner while waiting for the result
                            } else if (snapshot.hasError) {
                              return Text("Error: ${snapshot.error}"); // Handle any error
                            } else if (snapshot.hasData) {
                              return Text("Distance: ${snapshot.data!.toStringAsFixed(2)} km"); // Display the distance
                            } else {
                              return Text("No data available"); // Handle the case where there's no data
                            }
                          },
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StudentNearest(
                                  uid: route.driverId,
                                  user: widget.userModel,
                                ),
                              ),
                            );
                          },
                          child: Text("Check Route"),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else {
            return Center(child: Text("No data available"));
          }
        },
      );
    },
  );
}


Future<double> calculateDistanceFromCurrentLocation(double lat1, double lon1) async {
  // Get the current position of the user
  Position currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

  // Get the user's current latitude and longitude
  double lat2 = currentPosition.latitude;
  double lon2 = currentPosition.longitude;

  // Calculate the distance between the given coordinates and the current location
  double distanceInMeters = Geolocator.distanceBetween(lat1, lon1, lat2, lon2);

  // Convert the distance from meters to kilometers
  double distanceInKm = distanceInMeters / 1000;

  return distanceInKm; // Return the distance in kilometers
}
}
