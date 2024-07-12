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
  late TextEditingController _startLocationController;
  late TextEditingController _endLocationController;
  late TextEditingController _totalStopsController;
  LatLng? pickup;
  LatLng? destination;
  LatLng? stop;
  Marker? pickupMarker;
  Marker? destMarker;
  List<TextEditingController> _stopNameControllers = [];
  List<TextEditingController> _timeControllers = [];
  List<TextEditingController> _stopLocationControllers = [];
  int totalStops = 0;
  Set<Marker> markers = {};
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
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: Icon(
                              Icons.close,
                              color: Colors.red,
                            ))
                      ],
                    ),
                    SizedBox(height: 10.0),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(37.7749, -122.4194),
                              zoom: 15,
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
                              if (pickup != null)
                                Marker(
                                  infoWindow:
                                      InfoWindow(title: "pickup-location"),
                                  markerId: MarkerId('pick up location'),
                                  position: pickup!,
                                  draggable: true,
                                ),
                              if (destination != null)
                                Marker(
                                  infoWindow:
                                      InfoWindow(title: "Destination-location"),
                                  markerId: MarkerId('Destination location'),
                                  position: destination!,
                                  draggable: true,
                                ),
                            },
                            onMapCreated: (GoogleMapController controller) {},
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
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: Icon(
                              Icons.close,
                              color: Colors.red,
                            ))
                      ],
                    ),
                    SizedBox(height: 8.0),
                    Expanded(
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(37.7749, -122.4194),
                          zoom: 12,
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

                          Marker(
                            infoWindow: InfoWindow(title: "pickup-location"),
                            markerId: MarkerId('pickup-location'),
                            position: pickup!,
                            draggable: true,
                          ),
                          // Add marker for destination location
                          if (destinationLocation != null)
                            Marker(
                              infoWindow:
                                  InfoWindow(title: "destination-location"),
                              markerId: MarkerId('destination-location'),
                              position: destination!,
                              draggable: true,
                            ),
                        },
                        onMapCreated: (GoogleMapController controller) {},
                        gestureRecognizers: Set()
                          ..add(Factory<PanGestureRecognizer>(
                            () => PanGestureRecognizer(),
                          )),
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

  setMarker(LatLng point, String name) {
    setState(() {
      markers.add(
        Marker(
          infoWindow: InfoWindow(title: "$name"),
          markerId: MarkerId('$name'),
          position: point,
          draggable: true,
        ),
      );
    });
  }

///// ----------- Poly lines here between variable - pickup & detination-------------------------

  void selectLocation(int index) {
    // Variable to store the picked location
    LatLng? stopLocation;

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
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: Icon(
                              Icons.close,
                              color: Colors.red,
                            ))
                      ],
                    ),
                    SizedBox(height: 8.0),
                    Expanded(
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(37.7749, -122.4194),
                          zoom: 12,
                        ),
                        onTap: (LatLng position) {
                          setState(() {
                            stopLocation = position;
                            stop = position;
                          });
                          setMarker(stop!, "Stop - ${index + 1}");
                        },
                        markers: markers,
                        onMapCreated: (GoogleMapController controller) {},
                        gestureRecognizers: Set()
                          ..add(Factory<PanGestureRecognizer>(
                            () => PanGestureRecognizer(),
                          )),
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
                          fontSize: 12,
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
                  onTap: update,
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
