// ignore_for_file: use_build_context_synchronously, must_be_immutable

import 'package:first_bus_project/driver/manage-stops/driver_manage_stops_screen.dart';
import 'package:first_bus_project/driver/profile/driver_profile_screen.dart';
import 'package:first_bus_project/models/route_model.dart';
import 'package:first_bus_project/models/user_model.dart';
import 'package:first_bus_project/services/auth_service.dart';
import 'package:first_bus_project/welcome/welcome_screen.dart';
import 'package:first_bus_project/widgets/custom_button.dart';
import 'package:flutter/material.dart';

class DriverMenuScreen extends StatelessWidget {
  UserModel userModel;
  BusRouteModel? busRouteModel;
  DriverMenuScreen({
    super.key,
    required this.userModel,
    required this.busRouteModel,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final AuthService authService = AuthService();

    return Scaffold(
      backgroundColor: const Color(0XFF419A95),
      body: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: screenWidth * 0.08,
                  ),
                ),
              ),
            ),
            CircleAvatar(
              radius: screenWidth * 0.2,
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              userModel.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: screenHeight * 0.05,
                color: Colors.white,
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Divider(
              height: screenWidth * 0.02,
              color: Colors.white,
            ),
            ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DriverProfileScreen(
                      userModel: userModel,
                    ),
                  ),
                );
              },
              title: Text(
                "Profile",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: screenHeight * 0.025,
                  color: Colors.white,
                ),
              ),
            ),
            Divider(
              height: screenWidth * 0.02,
              color: Colors.white,
            ),
            ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DriverManageStops(
                      userModel: userModel,
                      busRouteModel: busRouteModel,
                    ),
                  ),
                );
              },
              title: Text(
                "Manage Stops",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: screenHeight * 0.025,
                  color: Colors.white,
                ),
              ),
            ),
            Divider(
              height: screenWidth * 0.0,
              color: Colors.white,
            ),
            SizedBox(height: screenHeight * 0.05),
            Container(
              width: double.infinity,
              height: screenHeight * 0.35,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(screenHeight * 0.03),
                  topRight: Radius.circular(screenHeight * 0.03),
                ),
              ),
              child: Center(
                child: CustomButton(
                  onTap: () async {
                    await authService.logout(context: context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WelcomeScreen(),
                      ),
                    );
                  },
                  text: "Logout",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
