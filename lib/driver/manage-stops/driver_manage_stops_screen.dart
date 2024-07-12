import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:first_bus_project/models/route_model.dart';
import 'package:first_bus_project/models/user_model.dart';
import 'package:first_bus_project/widgets/custom_button.dart';
import 'package:first_bus_project/widgets/custom_textfield.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class DriverManageStops extends StatefulWidget {
  final UserModel userModel;
  final BusRouteModel? busRouteModel;

  DriverManageStops({
    Key? key,
    required this.userModel,
    required this.busRouteModel,
  }) : super(key: key);

  @override
  State<DriverManageStops> createState() => _DriverManageStopsState();
}

class _DriverManageStopsState extends State<DriverManageStops> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Completer<GoogleMapController> _controller = Completer();
  late TextEditingController _startLocationController;
  late TextEditingController _endLocationController;
  late TextEditingController _totalStopsController;
  LatLng? pickup;
  LatLng? destination;
  LatLng? stop;
  Marker? pickupMarker;
  Marker? destMarker;
  Set<Marker> markers = {};
  List<LatLng> stops = [];
  LatLng? currentLocation;
  GoogleMapController? mapController;

  List<LatLng> polylineCoordinates = [];

  List<TextEditingController> _stopNameControllers = [];
  List<TextEditingController> _timeControllers = [];
  List<TextEditingController> _stopLocationControllers = [];
  int totalStops = 0;
  @override
  void initState() {
    print("---------------------------${widget.busRouteModel!.startLocation}");
    print(widget.busRouteModel!.endLocation);
    _startLocationController =
        TextEditingController(text: widget.busRouteModel!.startLocation);
    _endLocationController =
        TextEditingController(text: widget.busRouteModel!.endLocation);
    _totalStopsController = TextEditingController(
        text: widget.busRouteModel!.totalStops.toString());

    totalStops = widget.busRouteModel!.totalStops;
    _stopNameControllers = widget.busRouteModel!.stops
        .map((stop) => TextEditingController(text: stop.stopName))
        .toList();
    _timeControllers = widget.busRouteModel!.stops
        .map((stop) => TextEditingController(text: stop.time))
        .toList();
    _stopLocationControllers = widget.busRouteModel!.stops
        .map((stop) => TextEditingController(text: stop.stopLocation))
        .toList();

    super.initState();
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
    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(currentLocation!, 11),
    );
  }

  Future<Position> getUserCurrentLocation() async {
    await Geolocator.requestPermission().then((value) {
      print('error');
    });
    return await Geolocator.getCurrentPosition();
  }

  @override
  void dispose() {
    _startLocationController.dispose();
    _endLocationController.dispose();
    _totalStopsController.dispose();
    _stopNameControllers.forEach((controller) => controller.dispose());
    _timeControllers.forEach((controller) => controller.dispose());
    _stopLocationControllers.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void update() async {
    if (_formKey.currentState!.validate()) {
      final busRoute = BusRouteModel(
        startLocation: _startLocationController.text,
        endLocation: _endLocationController.text,
        totalStops: totalStops,
        stops: List.generate(totalStops, (index) {
          return Stop(
            stopName: _stopNameControllers[index].text,
            time: _timeControllers[index].text,
            stopLocation: _stopLocationControllers[index].text,
            isReached: false,
          );
        }),
      );

      try {
        await FirebaseFirestore.instance
            .collection('busRoutes')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .set(busRoute.toJson());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bus routes updated')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update bus routes: $e')),
        );
      }
    }
  }

  void getPickup() {
    LatLng? pickedLocation; // Variable to store the picked location

    showModalBottomSheet(
      isDismissible: false,
      isScrollControlled: false,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {}, // Prevents dismissing bottom sheet on tap
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                height: 500,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SizedBox(height: 10.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Set Your Pick Up Point',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                            onPressed: () async {
                              _onFabPressed();
                            },
                            icon: Icon(
                              Icons.room,
                              color: Colors.red,
                            )),
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: Icon(
                            Icons.close,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.0),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10)),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: currentLocation ??
                                      LatLng(37.7749, -122.4194),
                                  zoom: 11,
                                ),
                                onTap: (LatLng position) {
                                  setState(() {
                                    pickedLocation = position;
                                    pickup = position;
                                    pickupMarker = Marker(
                                      infoWindow:
                                          InfoWindow(title: "pickup-location"),
                                      markerId: MarkerId('pick up location'),
                                      position: pickup!,
                                      draggable: true,
                                    );
                                  });
                                  setMarker(pickup!, "pickup-location");
                                },
                                markers: {
                                  // Add marker for pickup location if available

                                  if (pickup != null)
                                    Marker(
                                      infoWindow:
                                          InfoWindow(title: "pickup-location"),
                                      markerId: MarkerId('pickup-location'),
                                      position: pickup!,
                                      draggable: true,
                                    ),
                                  // Add marker for destination location
                                  if (destination != null)
                                    Marker(
                                      infoWindow: InfoWindow(
                                          title: "destination-location"),
                                      markerId:
                                          MarkerId('destination-location'),
                                      position: destination!,
                                      draggable: true,
                                    ),
                                },
                                onMapCreated: (GoogleMapController controller) {
                                  setState(() {
                                    mapController = controller;
                                  });
                                },
                                gestureRecognizers: Set()
                                  ..add(Factory<PanGestureRecognizer>(
                                    () => PanGestureRecognizer(),
                                  )),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    GestureDetector(
                      onTap: () async {
                        if (pickedLocation != null) {
                          List<Placemark> placemarks =
                              await placemarkFromCoordinates(
                            pickedLocation!.latitude,
                            pickedLocation!.longitude,
                          );
                          Placemark place = placemarks.first;
                          _startLocationController.text =
                              "${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
                        }
                        Navigator.of(context).pop(); // Close the bottom sheet
                      },
                      child: Container(
                          alignment: Alignment.center,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.green[400],
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            "Confirm",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          )),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void getDestination() {
    LatLng? destinationLocation; // Variable to store the picked location

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {}, // Prevents dismissing bottom sheet on tap
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.all(16.0),
                height: 400,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Set Your Destination Point',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                            onPressed: () {
                              _onFabPressed();
                            },
                            icon: Icon(
                              Icons.room,
                              color: Colors.red,
                            )),
                        IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: Icon(
                              Icons.close,
                              color: Colors.red,
                            )),
                      ],
                    ),
                    SizedBox(height: 8.0),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(37.7749, -122.4194),
                              zoom: 11,
                            ),
                            onTap: (LatLng position) {
                              setState(() {
                                destinationLocation = position;
                                destination = position;
                                destMarker = Marker(
                                  infoWindow:
                                      InfoWindow(title: "Destination-location"),
                                  markerId: MarkerId('Destination-location'),
                                  position: destination!,
                                  draggable: true,
                                );
                              });
                              setMarker(destination!, "destination-location");
                            },
                            markers: {
                              // Add marker for pickup location if available

                              if (pickup != null)
                                Marker(
                                  infoWindow:
                                      InfoWindow(title: "pickup-location"),
                                  markerId: MarkerId('pickup-location'),
                                  position: pickup!,
                                  draggable: true,
                                ),
                              // Add marker for destination location
                              if (destination != null)
                                Marker(
                                  infoWindow:
                                      InfoWindow(title: "destination-location"),
                                  markerId: MarkerId('destination-location'),
                                  position: destination!,
                                  draggable: true,
                                ),
                            },
                            onMapCreated: (GoogleMapController controller) {
                              setState(() {
                                mapController = controller;
                              });
                            },
                            gestureRecognizers: Set()
                              ..add(Factory<PanGestureRecognizer>(
                                () => PanGestureRecognizer(),
                              )),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    GestureDetector(
                      onTap: () async {
                        if (destinationLocation != null) {
                          List<Placemark> placemarks =
                              await placemarkFromCoordinates(
                            destinationLocation!.latitude,
                            destinationLocation!.longitude,
                          );
                          Placemark place = placemarks.first;
                          _endLocationController.text =
                              "${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
                        }
                        Navigator.of(context).pop();
                      },
                      child: Container(
                          alignment: Alignment.center,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.green[400],
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            "Confirm",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          )),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void selectLocation(int index) {
    LatLng? stopLocation;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.all(16.0),
                height: 400,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Set Your Stops',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            _onFabPressed();
                          },
                          icon: Icon(
                            Icons.room,
                            color: Colors.red,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: Icon(
                            Icons.close,
                            color: Colors.red,
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: 8.0),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(37.7749, -122.4194),
                              zoom: 11,
                            ),
                            onTap: (LatLng position) {
                              setState(() {
                                stopLocation = position;
                                stop = position;

                                setMarker(stop!, "Stop - ${index + 1}");
                              });
                            },
                            markers: markers,
                            onMapCreated: (GoogleMapController controller) {
                              setState(() {
                                mapController = controller;
                              });
                            },
                            gestureRecognizers: Set()
                              ..add(
                                Factory<PanGestureRecognizer>(
                                  () => PanGestureRecognizer(),
                                ),
                              ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    GestureDetector(
                      onTap: () async {
                        if (stopLocation != null) {
                          List<Placemark> placemarks =
                              await placemarkFromCoordinates(
                            stopLocation!.latitude,
                            stopLocation!.longitude,
                          );
                          Placemark place = placemarks.first;
                          _stopLocationControllers[index].text =
                              "${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
                          print(_stopLocationControllers[index].text);
                        }
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        alignment: Alignment.center,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.green[400],
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          "Confirm",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

// -----------------with PolyLines ----------------------------------------------
  void polyLinesbwpickandDest() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {}, // Prevents dismissing bottom sheet on tap
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.all(16.0),
                height: 500,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SizedBox(height: 10.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Set Your Route',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            _onFabPressed();
                          },
                          icon: Icon(
                            Icons.room,
                            color: Colors.red,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: Icon(
                            Icons.close,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.0),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(37.7749, -122.4194),
                              zoom: 11,
                            ),
                            markers: markers,
                            polylines: _createPolylines(),
                            onMapCreated: (GoogleMapController controller) {
                              mapController = controller;
                            },
                            onTap: (LatLng position) {
                              setState(() {
                                if (pickup == null) {
                                  pickup = position;
                                  _addMarker(position, 'Pickup');
                                } else if (destination == null) {
                                  destination = position;
                                  _addMarker(position, 'Destination');
                                  _fetchRoute(
                                      pickup!.latitude,
                                      pickup!.longitude,
                                      destination!.latitude,
                                      destination!.longitude);
                                }
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    GestureDetector(
                      onTap: () async {
                        update();
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        alignment: Alignment.center,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.green[400],
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          "Confirm",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
    );
  }

  Set<Polyline> _createPolylines() {
    Set<Polyline> polylines = {};

    List<LatLng> allPoints = [];

    if (pickup != null) {
      allPoints.add(pickup!);
    }

    allPoints.addAll(stops);

    if (destination != null) {
      allPoints.add(destination!);
    }

    if (allPoints.length > 1) {
      List<LatLng> polylinePoints = [];
      for (int i = 0; i < allPoints.length; i++) {
        polylinePoints.add(allPoints[i]);
      }

      polylines.add(Polyline(
        polylineId: PolylineId('route'),
        color: Colors.blue,
        width: 5,
        points: polylinePoints,
      ));
    }

    return polylines;
  }

  void setMarker(LatLng point, String name) {
    setState(() {
      markers.add(
        Marker(
          markerId: MarkerId(name),
          position: point,
          infoWindow: InfoWindow(title: name),
          draggable: true,
        ),
      );
      setState(() {
        _createPolylines();
      });
    });
  }

  void _addMarker(LatLng position, String title) {
    setState(() {
      markers.add(
        Marker(
          markerId: MarkerId(title),
          position: position,
          infoWindow: InfoWindow(title: title),
        ),
      );
    });
  }

  void addPolyline() {
    if (polylineCoordinates.isNotEmpty) {
      markers.add(
        Marker(
          markerId: MarkerId('route'),
          position: polylineCoordinates.first,
        ),
      );
    }
  }

  Future<void> _fetchRoute(
      double startLat, double startLon, double endLat, double endLon) async {
    final apiKey = 'AIzaSyA7cE8WGvcgtU-3eci8pkt3KBjE-tE1Yzc';
    final url = 'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=$startLat,$startLon&'
        'destination=$endLat,$endLon&'
        'key=$apiKey';
    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['status'] == 'OK') {
      final List<dynamic> routes = data['routes'];
      if (routes.isNotEmpty) {
        final String points = routes[0]['overview_polyline']['points'];
        polylineCoordinates = _convertToLatLng(_decodePoly(points));

        setState(() {
          if (polylineCoordinates.isNotEmpty) {
            _addPolyline();
          }
        });
      }
    }
  }

  List<LatLng> _convertToLatLng(List points) {
    List<LatLng> result = [];
    for (int i = 0; i < points.length; i++) {
      if (i % 2 != 0) {
        result.add(LatLng(points[i - 1], points[i]));
      }
    }
    return result;
  }

  List _decodePoly(String poly) {
    var list = poly.codeUnits;
    var lList = [];
    int index = 0;
    int len = poly.length;
    int c = 0;
    do {
      var shift = 0;
      int result = 0;
      do {
        c = list[index] - 63;
        result |= (c & 0x1F) << (shift * 5);
        index++;
        shift++;
      } while (c >= 32);
      if (result & 1 == 1) {
        result = ~result;
      }
      var result1 = (result >> 1) * 0.00001;
      lList.add(result1);
    } while (index < len);
    for (var i = 2; i < lList.length; i++) lList[i] += lList[i - 2];
    return lList;
  }

  void _addPolyline() {
    setState(() {
      markers.add(
        Marker(
          markerId: MarkerId('route'),
          position: polylineCoordinates.first,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.08),
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: const Color(0XFF419A95),
                      size: screenWidth * 0.08,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.025),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Stops',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: screenWidth * 0.08,
                      ),
                    ),
                    Text(
                      'Click on location icon to open maps',
                      style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.025),
                CustomFields(
                  icon: IconButton(
                    onPressed: () {
                      setState(() {});
                      getPickup();
                    },
                    icon: Icon(
                      Icons.location_pin,
                    ),
                    color: Color(0XFF419A95),
                  ),
                  isPassword: false,
                  controller: _startLocationController,
                  keyboardType: TextInputType.none,
                  text: 'Pickup',
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter the start location';
                    }
                    return null;
                  },
                ),
                SizedBox(height: screenHeight * 0.025),
                CustomFields(
                  icon: IconButton(
                    onPressed: getDestination,
                    icon: Icon(
                      Icons.location_pin,
                    ),
                    color: Color(0XFF419A95),
                  ),
                  isPassword: false,
                  controller: _endLocationController,
                  keyboardType: TextInputType.none,
                  text: 'Destination',
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter the end location';
                    }
                    return null;
                  },
                ),
                SizedBox(height: screenHeight * 0.025),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Stops',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.025),
                totalStops == 0
                    ? TextFormField(
                        controller: _totalStopsController,
                        onFieldSubmitted: (value) {
                          setState(() {
                            totalStops = int.parse(value);
                            _stopNameControllers = List.generate(
                                totalStops, (index) => TextEditingController());
                            _timeControllers = List.generate(
                                totalStops, (index) => TextEditingController());
                            _stopLocationControllers = List.generate(
                                totalStops, (index) => TextEditingController());
                          });
                        },
                        textInputAction: TextInputAction.done,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          suffixIcon: Icon(
                            Icons.add_location,
                            color: Colors.grey,
                          ),
                          labelText: 'Number of stops',
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xffB81736),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(10),
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter the number of stops';
                          }
                          return null;
                        },
                      )
                    : Column(
                        children: List.generate(
                          totalStops,
                          (index) => Column(
                            children: [
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    SizedBox(
                                      width: screenWidth * 0.5,
                                      child: CustomFields(
                                        isPassword: false,
                                        controller: _stopNameControllers[index],
                                        keyboardType: TextInputType.name,
                                        text: 'Stop Name',
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return 'Please enter the stop name';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    SizedBox(
                                      width: screenWidth * 0.5,
                                      child: CustomFields(
                                        isPassword: false,
                                        controller: _timeControllers[index],
                                        keyboardType: TextInputType.name,
                                        text: 'Stop Time',
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return 'Please enter the stop time';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 10),

                                    //////------------------------------- Select location container -----------------------------
                                    GestureDetector(
                                      onTap: () {
                                        selectLocation(index);
                                      },
                                      child: Container(
                                          alignment: Alignment.center,
                                          height: 55,
                                          width: screenWidth * 0.4,
                                          decoration: BoxDecoration(
                                            color: _stopLocationControllers
                                                    .contains(index)
                                                ? Colors.red
                                                : Color(0XFF419A95),
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          child: const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Text("Select location",
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.white)),
                                              Icon(Icons.room,
                                                  color: Colors.white),
                                            ],
                                          )),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.025),
                            ],
                          ),
                        ),
                      ),
                SizedBox(height: screenHeight * 0.025),
                CustomButton(
                  onTap: polyLinesbwpickandDest,
                  text: 'Update',
                ),
                SizedBox(height: screenHeight * 0.025),
              ],
            ),
          ),
        ),
      ),
    );
  }

  showStopModel(BuildContext context) {}
}
