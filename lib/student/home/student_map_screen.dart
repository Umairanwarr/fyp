// ignore_for_file: must_be_immutable

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:first_bus_project/models/route_model.dart';
import 'package:first_bus_project/models/user_model.dart';
import 'package:first_bus_project/services/routes_services.dart';
import 'package:first_bus_project/student/home/student_nearest_stop.dart';
import 'package:first_bus_project/student/menu/student_menu.dart';
import 'package:first_bus_project/student/student_route.dart';
import 'package:first_bus_project/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class StudentMapScreen extends StatefulWidget {
  UserModel userModel;
  StudentMapScreen({
    super.key,
    required this.userModel,
  });

  @override
  State<StudentMapScreen> createState() => _StudentMapScreenState();
}

class _StudentMapScreenState extends State<StudentMapScreen> {
  GoogleMapController? mapController;
  LatLng? currentLocation;
  Map<List<dynamic>, List<LatLng>> routes = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Marker? pickupMarker;
  Marker? destMarker;
  Map<String, List<LatLng>> allCords = {};
  List<bool> isRemember = [];
  String? selectedRouteId;

  LatLng? pickup, destination;
  Set<Marker> totalMarkers = {};
  Set<Marker> stopMarkers = {};
  List<BusRouteModel>? buses;
  @override
  void initState() {
    getBuses();
    super.initState();
  }

  void getBuses() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('busRoutes').get();

      setState(() {
        querySnapshot.docs.forEach((doc) {
          BusRouteModel bus = BusRouteModel.fromFirestore(
              doc.data() as Map<String, dynamic>, doc.id);

          List<LatLng> busCords = [];

          // Add startCords
          busCords.add(bus.startCords);
          String docId = bus.id;
          // Add each stop's coordinates to `busCords`
          bus.stops.forEach((stop) {
            busCords.add(stop.stopCords);
          });
          busCords.add(bus.endCords);

          allCords[docId] = busCords;
        });
      });
    } catch (e) {
      print("Error fetching buses: $e");
      // Handle error fetching data
    }
  }

  final RoutesService _routesService = RoutesService();

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
    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(currentLocation!, 13),
    );
  }

  void setMarker(
      LatLng point, String name, String? time, BitmapDescriptor icon) {
    final MarkerId markerId = MarkerId(name);

    // Convert stopMarkers Set to a List to find existing markers
    List<Marker> markersList = stopMarkers.toList();

    // Check if the marker with the given name already exists
    int existingIndex =
        markersList.indexWhere((marker) => marker.markerId.value == name);

    setState(() {
      if (existingIndex != -1) {
        // Update existing marker if found
        markersList[existingIndex] = Marker(
          markerId: MarkerId(name),
          position: point,
          infoWindow: (time != null)
              ? InfoWindow(title: name + time)
              : InfoWindow(title: name),
          draggable: true,
          icon: icon,
        );

        // Convert back to Set after modification
        stopMarkers = markersList.toSet();
      } else {
        // Add new marker if not found
        stopMarkers.add(
          Marker(
            markerId: MarkerId(name),
            position: point,
            infoWindow: (time != null)
                ? InfoWindow(title: name + time)
                : InfoWindow(title: name),
            draggable: true,
            icon: icon,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Student Map'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentMenuScreen(
                    userModel: widget.userModel,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.person),
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10),
            margin: EdgeInsets.only(bottom: 10),
            height: MediaQuery.of(context).size.height * 0.5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: GoogleMap(
                onMapCreated: (GoogleMapController controller) async {
                  setState(() {
                    mapController = controller;
                  });
                  await _getCurrentLocation();
                  mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(currentLocation!, 11),
                  );
                },
                polylines: _createPolylines(),
                markers: totalMarkers,
                initialCameraPosition: CameraPosition(
                  target: currentLocation ?? LatLng(33.7445, 72.7867),
                  zoom: 12,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore.collection('busRoutes').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                List<String> docs = [];

                List<BusRouteModel> busRoutes = snapshot.data!.docs.map((doc) {
                  docs.add(doc.id);
                  return BusRouteModel.fromFirestore(doc.data(), doc.id);
                }).toList();

                return ListView.builder(
                  itemCount: busRoutes.length,
                  itemBuilder: (context, index) {
                    BusRouteModel route = busRoutes[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedRouteId = route.id;
                        });
                      },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        margin:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                        decoration: BoxDecoration(
                          color: selectedRouteId == route.id
                              ? const Color.fromRGBO(76, 175, 80, 1)
                                  .withOpacity(0.4)
                              : Colors.blue.withOpacity(0.0),
                          border:
                              Border.all(color: Colors.green.withOpacity(0.4)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              route.startLocation,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                            if (route.stops.isNotEmpty &&
                                index < route.stops.length)
                              Text(
                                "Time : ${route.startTime}",
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600]),
                              ),
                            InkWell(
                              onTap: () {
                                print("--------------------${route.driverId}");
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          StudentNearest(uid: route.driverId),
                                    ));
                              },
                              child: Container(
                                width: double.infinity,
                                height: 50,
                                alignment: Alignment.center,
                                margin: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                                decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(5)),
                                child: Text(
                                  "Check Stop",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.room),
          onPressed: () {
            _onFabPressed();
          }),
    );
  }

// -----------------with PolyLines ----------------------------------------------
  Set<Polyline> _createPolylines() {
    Set<Polyline> polylines = {};

    allCords.forEach((docId, coordinates) {
      if (coordinates.length > 1) {
        List<LatLng> polylinePoints = [];
        for (int i = 0; i < coordinates.length; i++) {
          polylinePoints.add(coordinates[i]);
        }
        print("=====================================${selectedRouteId}");
        print("=====================================${docId}");

        Color color = (selectedRouteId == docId)
            ? Colors.blueAccent
            : Colors.grey.withOpacity(0.6);
        polylines.add(Polyline(
          polylineId:
              PolylineId(docId), // Use docId as polyline ID for uniqueness
          color: color,
          width: 5,
          points: polylinePoints,
        ));
      }
    });

    return polylines;
  }

  Color getRandomColor() {
    Random random = Random();
    // Generate random RGB values
    int r = random.nextInt(256);
    int g = random.nextInt(256);
    int b = random.nextInt(256);
    // Return a Color object with random values
    return Color.fromARGB(255, r, g, b);
  }
}
