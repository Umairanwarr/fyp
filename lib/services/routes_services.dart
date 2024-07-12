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
                        

      DocumentSnapshot doc =
          await _firestore.collection('busRoutes').doc(userId).get();
      if (doc.exists) {
        print("---------------------------${doc.data()}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bus route fetched successfully')),
        );
        return BusRouteModel.fromJson(doc.data() as Map<String, dynamic>);
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
