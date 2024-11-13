// ignore_for_file: must_be_immutable

import 'package:first_bus_project/driver/menu/driver_menu.dart';
import 'package:first_bus_project/models/route_model.dart';
import 'package:first_bus_project/models/user_model.dart';
import 'package:flutter/material.dart';

class DriverMapScreen extends StatefulWidget {
  UserModel userModel;
  BusRouteModel? busRouteModel;
  DriverMapScreen({
    super.key,
    required this.userModel,
    required this.busRouteModel,
  });

  @override
  State<DriverMapScreen> createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends State<DriverMapScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Driver Map'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DriverMenuScreen(
                    userModel: widget.userModel,
                    busRouteModel: widget.busRouteModel,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.person),
          )
        ],
      ),
    );
  }
}
