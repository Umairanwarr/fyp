// ignore_for_file: must_be_immutable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:first_bus_project/driver/home/TimeLineTile.dart';
import 'package:first_bus_project/models/user_model.dart';
import 'package:first_bus_project/services/routes_services.dart';
import 'package:first_bus_project/student/menu/student_menu.dart';
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();

    _getCurrentLocation();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Map'),
        automaticallyImplyLeading: false,
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
                initialCameraPosition: CameraPosition(
                  target: currentLocation ?? LatLng(37.7749, -122.4194),
                  zoom: 11,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    children: [
                      TimeLineTileWidget(
                        isfirst: true,
                        islast: false,
                        text: 'Margalla hills - 723A\n7:30 am',
                      ),
                      TimeLineTileWidget(
                        isfirst: false,
                        islast: false,
                        text: 'Margalla hills - 723A\n7:30 am',
                      ),
                      TimeLineTileWidget(
                        isfirst: false,
                        islast: false,
                        text: 'Margalla hills - 723A\n7:30 am',
                      ),
                      TimeLineTileWidget(
                        isfirst: false,
                        islast: true,
                        text: 'Margalla hills - 723A\n7:30 am',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onFabPressed,
        child: Icon(Icons.location_searching),
      ),
    );
  }
}
