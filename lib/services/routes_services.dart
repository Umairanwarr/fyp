// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:first_bus_project/models/route_model.dart';
import 'package:flutter/material.dart';

class RoutesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveBusRoute(
      BuildContext context, String userId, BusRouteModel busRoute) async {
    try {
      await _firestore
          .collection('busroutes')
          .doc(userId)
          .set(busRoute.toJson());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bus route saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving bus route: $e')),
      );
    }
  }

  Future<BusRouteModel> getBusRoute(
    BuildContext context,
    String userId,
  ) async {

    try {
                        
DocumentSnapshot<Map<String, dynamic>> doc =
      await FirebaseFirestore.instance.collection('busRoutes').doc(userId).get();

      if (doc.exists) {
        // print("---------------------------${doc.data()}");
        String end = doc['endLocation'];
        
     BusRouteModel bus = BusRouteModel.fromFirestore(doc.data()!, doc.id);
     print("---------------------------${doc['endLocation']}");
    print("---------------------------${bus.endLocation}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bus route fetched successfully')),
        );

        return bus;
      } else {
        
        return BusRouteModel.empty();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching bus route: $e')),
      );
      return BusRouteModel.empty();
    }
  }
}
