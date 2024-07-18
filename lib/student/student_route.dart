import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:first_bus_project/models/route_model.dart';
import 'package:first_bus_project/models/user_model.dart';
import 'package:first_bus_project/services/routes_services.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:timeline_tile/timeline_tile.dart';

class StudentRoute extends StatefulWidget {
  final String uid;
  StudentRoute({super.key, required this.uid});

  @override
  State<StudentRoute> createState() => _StudentRouteState();
}

class _StudentRouteState extends State<StudentRoute> {
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
  bool isLoading = true;

  @override
  void initState() {
    getData();
    _getCurrentLocation();
    super.initState();
  }

  Future<void> getData() async {
    try {
      DocumentSnapshot busDoc = await _firestore.collection('busRoutes').doc(widget.uid).get();
      DocumentSnapshot driverDoc = await _firestore.collection('users').doc(widget.uid).get();

      setState(() {
        bus = BusRouteModel.fromFirestore(busDoc.data() as Map<String, dynamic>, busDoc.id);
        driver = UserModel.fromFirestore(driverDoc.data() as Map<String, dynamic>, driverDoc.id);
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
      CameraUpdate.newLatLngZoom(currentLocation!, 15),
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
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
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
                      onMapCreated: (GoogleMapController controller) {
                        setState(() {
                          mapController = controller;
                        });
                      },
                      polylines: _createPolylines(),
                      markers: totalMarkers,
                      initialCameraPosition: CameraPosition(
                        target: pickup!,
                        zoom: 14,
                      ),
                    ),
                  ),
                ),
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
                                  backgroundImage: NetworkImage(driver!.profileImageUrl ?? 'https://via.placeholder.com/150'),
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
                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      "Check driver details",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(10),
                    itemCount: bus?.totalStops ?? 0,
                    itemBuilder: (context, index) {
                      return TimelineTile(
                        alignment: TimelineAlign.start,
                        isFirst: index == 0,
                        isLast: bus!.stops.length == index + 1,
                        indicatorStyle: IndicatorStyle(
                          width: 20,
                          color: Colors.black,
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          indicator: Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        endChild: Container(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              margin: EdgeInsets.all(4),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isRemember[index]
                                    ? Colors.green
                                    : Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bus!.stops[index].stopName,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    bus!.stops[index].time ?? 'No time provided',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onFabPressed,
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




