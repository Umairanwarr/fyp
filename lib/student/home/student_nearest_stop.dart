import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:first_bus_project/models/route_model.dart';
import 'package:first_bus_project/models/user_model.dart';
import 'package:first_bus_project/services/routes_services.dart';
import 'package:first_bus_project/student/student_route.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:timeline_tile/timeline_tile.dart';

class StudentNearest extends StatefulWidget {
  final String uid;
  StudentNearest({super.key, required this.uid});

  @override
  State<StudentNearest> createState() => _StudentNearestState();
}

class _StudentNearestState extends State<StudentNearest> {
  GoogleMapController? mapController;
  LatLng? currentLocation;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Marker? pickupMarker;
  Marker? destMarker;
  List<LatLng> allCords = [];
  List<bool> isRemember = [];
  LatLng? pickup, destination;
  Set<Marker> totalMarkers = {};
  Set<Marker> stopMarkers = {};
  BusRouteModel? bus;
  UserModel? driver;
  Marker? nearestStop;
  bool isLoading = true;

  @override
  void initState() {
    _onFabPressed();
    getData();
    _getCurrentLocation();
    findNearestMarker(stopMarkers);
    delay();

    super.initState();
  }

  findNearestMarker(Set<Marker> markers) async {
    Position userLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    double userLatitude = userLocation.latitude;
    double userLongitude = userLocation.longitude;

    Marker? nMarker;
    double shortestDistance = double.infinity;

    for (Marker marker in markers) {
      double markerLatitude = marker.position.latitude;
      double markerLongitude = marker.position.longitude;

      double distance = Geolocator.distanceBetween(
          userLatitude, userLongitude, markerLatitude, markerLongitude);

      print("--------------------------------$distance");

      if (distance < shortestDistance) {
        shortestDistance = distance;
        nMarker = marker;
      }
    }

    setState(() {
      nearestStop = nMarker;
    });
  }

  delay() async {
    await Future.delayed(Duration(seconds: 2));
  }

  Future<void> getData() async {
    try {
      DocumentSnapshot busDoc =
          await _firestore.collection('busRoutes').doc(widget.uid).get();
      DocumentSnapshot driverDoc =
          await _firestore.collection('users').doc(widget.uid).get();

      setState(() {
        bus = BusRouteModel.fromFirestore(
            busDoc.data() as Map<String, dynamic>, busDoc.id);
        driver = UserModel.fromFirestore(
            driverDoc.data() as Map<String, dynamic>, driverDoc.id);
        updateData();
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void updateData() {
    allCords.add(bus!.startCords);
    for (var v in bus!.stops) {
      allCords.add(v.stopCords);
      isRemember.add(v.isReached);
    }

    allCords.add(bus!.endCords);
    pickup = bus!.startCords;
    destination = bus!.endCords;
    pickupMarker = Marker(
      markerId: MarkerId("pickupLocation"),
      infoWindow: InfoWindow(
        title: "pickupLocation",
      ),
      position: pickup!,
    );
    destMarker = Marker(
      markerId: MarkerId("destLocation"),
      infoWindow: InfoWindow(title: "destination"),
      position: destination!,
    );

    for (var stop in bus!.stops) {
      setMarker(
        stop.stopCords,
        stop.stopName,
        stop.time,
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );
    }
    totalMarkers.add(destMarker!);
    totalMarkers.addAll(stopMarkers);
    totalMarkers.add(pickupMarker!);
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
      CameraUpdate.newLatLngZoom(currentLocation!, 11),
    );
  }

  void setMarker(
      LatLng point, String name, String? time, BitmapDescriptor icon) {
    final MarkerId markerId = MarkerId(name);

    List<Marker> markersList = stopMarkers.toList();

    int existingIndex =
        markersList.indexWhere((marker) => marker.markerId.value == name);

    setState(() {
      if (existingIndex != -1) {
        markersList[existingIndex] = Marker(
          markerId: MarkerId(name),
          position: point,
          infoWindow: (time != null)
              ? InfoWindow(title: name)
              : InfoWindow(title: name),
          draggable: true,
          icon: icon,
        );

        stopMarkers = markersList.toSet();
      } else {
        stopMarkers.add(
          Marker(
            markerId: MarkerId(name),
            position: point,
            infoWindow: (time != null)
                ? InfoWindow(title: name)
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
      backgroundColor: Colors.white70.withOpacity(0.9),
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  margin: EdgeInsets.only(bottom: 10),
                  height: MediaQuery.of(context).size.height * 0.50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: GoogleMap(
                      onMapCreated: (GoogleMapController controller) {
                        setState(() {
                          mapController = controller;
                        });
                      },
                      polylines: _createPolylines(),
                      markers: {
                        pickupMarker!,
                        destMarker!,
                        if (nearestStop != null) nearestStop!,
                      },
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          nearestStop?.position.latitude ?? 0,
                          nearestStop?.position.longitude ?? 0,
                        ),
                        zoom: 11,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    width: MediaQuery.of(context).size.width * 0.90,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15))),
                    height: MediaQuery.of(context).size.height * 0.35,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: SizedBox(
                                width: 70,
                                child: Divider(
                                    thickness: 5, color: Colors.grey[400])),
                          ),
                          Text("Nearest Stop",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Padding(
                            padding: const EdgeInsets.only(left: 20.0),
                            child: (nearestStop != null)
                                ? Text(
                                    "Stop name: ${nearestStop!.infoWindow.title}",
                                    style: TextStyle(
                                      fontSize: 18,
                                    ))
                                : Text("Stop name: ${"Getting . . ."}",
                                    style: TextStyle(
                                      fontSize: 18,
                                    )),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 20.0),
                            child: (nearestStop != null)
                                ? Text("${"Ariving at ${bus!.startTime}"}",
                                    style: TextStyle(
                                      fontSize: 18,
                                    ))
                                : Text("Getting . . .",
                                    style: TextStyle(
                                      fontSize: 18,
                                    )),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 20.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                    overflow: TextOverflow.ellipsis,
                                    'Bus Number: ${driver?.busNumber ?? 'Loading...'}',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                Text(
                                    overflow: TextOverflow.ellipsis,
                                    'Color: ${driver?.busColor ?? 'Loading...'}',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          SizedBox(height: 5),
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('Driver Details'),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        children: [
                                          CircleAvatar(
                                            radius: 40,
                                            backgroundImage: NetworkImage(driver!
                                                    .profileImageUrl ??
                                                'https://via.placeholder.com/150'),
                                          ),
                                          SizedBox(height: 10),
                                          Text(
                                            driver?.name ?? 'Loading...',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 10),
                                          Text(
                                            'Email: ${driver?.email ?? 'Loading...'}',
                                            style: TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                          SizedBox(height: 10),
                                          Text(
                                            'Phone: ${driver?.phone ?? 'Loading...'}',
                                            style: TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                          SizedBox(height: 10),
                                          Text(
                                            'Bus Number: ${driver?.busNumber ?? 'Loading...'}',
                                            style: TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text('Close'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              height: 50,
                              alignment: Alignment.center,
                              margin: EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFF419A95),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                "Check driver details",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          SizedBox(height: 5),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        StudentRoute(uid: widget.uid),
                                  ));
                            },
                            child: Container(
                              width: double.infinity,
                              height: 50,
                              alignment: Alignment.center,
                              margin: EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFF419A95),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                "View all stops",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _onFabPressed();

          findNearestMarker(stopMarkers);
        },
        child: Icon(Icons.location_searching),
      ),
    );
  }

  Set<Polyline> _createPolylines() {
    Set<Polyline> polylines = {};

    List<LatLng> allCords = [];
    allCords.add(bus!.startCords);
    for (var v in bus!.stops) {
      allCords.add(v.stopCords);
    }
    allCords.add(bus!.endCords);

    polylines.add(
      Polyline(
        polylineId: PolylineId('route'),
        visible: true,
        points: allCords,
        color: Colors.blue,
        width: 4,
      ),
    );

    return polylines;
  }
}
