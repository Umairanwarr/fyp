// ignore_for_file: must_be_immutable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:first_bus_project/models/route_model.dart';
import 'package:first_bus_project/models/user_model.dart';
import 'package:first_bus_project/services/auth_service.dart';
import 'package:first_bus_project/services/routes_services.dart';
import 'package:first_bus_project/widgets/custom_button.dart';
import 'package:first_bus_project/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';

class DriverManageStops extends StatefulWidget {
  UserModel userModel;
  BusRouteModel? busRouteModel;
  DriverManageStops({
    super.key,
    required this.userModel,
    required this.busRouteModel,
  });

  @override
  State<DriverManageStops> createState() => _DriverManageStopsState();
}

class _DriverManageStopsState extends State<DriverManageStops> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _startLocationController;
  late TextEditingController _endLocationController;
  late TextEditingController _totalStopsController;
  List<TextEditingController> _stopNameControllers = [];
  List<TextEditingController> _timeControllers = [];
  List<TextEditingController> _stopLocationControllers = [];
  int totalStops = 0;

  @override
  void initState() {
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

    super.initState();
  }

  @override
  void dispose() {
    _startLocationController.dispose();
    _endLocationController.dispose();
    _totalStopsController.dispose();
    for (var controller in _stopNameControllers) {
      controller.dispose();
    }
    for (var controller in _timeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void update() async{
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

// ------------------ Select location container method ------------------

  void selectLocation(int index){
   
    String location = ""; /// ========== ya map sa ay gi 
_stopLocationControllers[index].text = location;
//  for (var controller in _stopLocationControllers) {
//     print(controller.text);
//   }
showDialog(context: context, builder: (context) => Dialog(
  child: Container(
height: 200,
child: Column(
  children: [
    SizedBox(height: 10,),
    Text("Stop number: ${index+1}"),
  ],
)
    //yaha google maps lagain aik method 
  ),
),);
  }

  getPickup(){
showDialog(context: context, builder: (context) => Dialog(
  child: Container(
height: 200,
child: Column(
  children: [
    SizedBox(height: 10,),
    Text("Pick up location"),
  ],
)
    //yaha google maps lagain aik method 
  ),
),);
  }

  getDestination(){
showDialog(context: context, builder: (context) => Dialog(
  child: Container(
height: 200,
child: Column(
  children: [
    SizedBox(height: 10,),
    Text("Destination location"),
  ],
)
    //yaha google maps lagain aik method 
  ),
),);
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
                Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    'Stops',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: screenWidth * 0.08,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.025),
                CustomFields(
                  icon:  IconButton(
                    onPressed: () {
                      getPickup();
                    },
                    icon: Icon(Icons.location_pin,),
                    color: Color(0XFF419A95),
                  ),
                  isPassword: false,
                  controller: _startLocationController,
                  keyboardType: TextInputType.name,
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
                  icon:  IconButton(
                    onPressed: () {
                      getDestination();
                    },
                    icon: Icon(Icons.location_pin,),
                    color: Color(0XFF419A95),
                  ),
                  isPassword: false,
                  controller: _endLocationController,
                  keyboardType: TextInputType.name,
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
                                        icon: const Icon(
                                          Icons.location_pin,
                                          color: Colors.grey,
                                        ),
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
                                        icon: const Icon(
                                          Icons.location_pin,
                                          color: Colors.grey,
                                        ),
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
                                      onTap: (){
                                        selectLocation(index);
                                      },
                                      child: Container(
                                        alignment: Alignment.center,
                                        height: 55,
                                        width: screenWidth * 0.4,
                                        decoration: BoxDecoration(
                                          color: _stopLocationControllers.contains(index) ? Colors.red : Color(0XFF419A95), 
                                          borderRadius: BorderRadius.circular(5),
                                          
                                        ),child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Text("Select location", style: TextStyle(color: Colors.white)),
                                            Icon(Icons.room, color: Colors.white),
                                          
                                          ],
                                        )
                                      ),
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
}
