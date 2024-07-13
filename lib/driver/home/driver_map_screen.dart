import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:first_bus_project/driver/home/TimeLineTile.dart';
import 'package:first_bus_project/services/routes_services.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:first_bus_project/driver/menu/driver_menu.dart';
import 'package:first_bus_project/models/route_model.dart';
import 'package:first_bus_project/models/user_model.dart';

class DriverMapScreen extends StatefulWidget {
  final UserModel userModel;
  final BusRouteModel? busRouteModel;

  DriverMapScreen({
    Key? key,
    required this.userModel,
    required this.busRouteModel,
  }) : super(key: key);

  @override
  State<DriverMapScreen> createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends State<DriverMapScreen> {
  GoogleMapController? mapController;
  LatLng? currentLocation;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Marker? pickupMarker;
  Marker? destMarker;
List<LatLng> allCords = [];
 LatLng? pickup,destination;
 Set<Marker> totalMarkers = {};
 Set<Marker> stopMarkers = {};
  @override
  void initState() {
    super.initState();
    allCords.add(widget.busRouteModel!.startCords);
    for(var v in widget.busRouteModel!.stops){
allCords.add(v.stopCords);
    }
    
    allCords.add(widget.busRouteModel!.endCords);
    pickup = widget.busRouteModel!.startCords;
      destination = widget.busRouteModel!.endCords;
    pickupMarker =
          Marker(markerId: MarkerId("pickupLocation"),infoWindow: InfoWindow(title: "pickupLocation", ), position: pickup!);
      destMarker =
          Marker(markerId: MarkerId("destLocation"),infoWindow: InfoWindow(title: "destination"), position: destination!);

          for (var stop in widget.busRouteModel!.stops) {
     
        setMarker(stop.stopCords, stop.stopName, stop.time,
            BitmapDescriptor.defaultMarkerWithHue(
                                      BitmapDescriptor
                                          .hueBlue),);
      }
          totalMarkers.add(destMarker!);
      totalMarkers.addAll(stopMarkers);
      totalMarkers.add(pickupMarker!);
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
                polylines:  _createPolylines(),
                markers: totalMarkers,
                initialCameraPosition: CameraPosition(
                  target: currentLocation ?? LatLng(37.7749, -122.4194),
                  zoom: 12,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
      padding: EdgeInsets.all(10),
      itemCount: widget.busRouteModel!.totalStops,
      itemBuilder: (context, index) {
        final stop = widget.busRouteModel!.stops[index];
        return TimeLineTileWidget(
          isfirst: index == 0,
          islast: index == widget.busRouteModel!.stops.length - 1,
          text: '${stop.stopName}\n${stop.time}',
        );
      },
    )
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _onFabPressed,
      //   child: Icon(Icons.location_searching),
      // ),
    );
  }





  
// -----------------with PolyLines ----------------------------------------------
 
  Set<Polyline> _createPolylines() {
    Set<Polyline> polylines = {};

    List<LatLng> allPoints = [];
    allPoints.addAll(allCords);

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

}
