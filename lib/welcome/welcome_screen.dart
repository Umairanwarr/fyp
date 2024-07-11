import 'package:first_bus_project/driver/auth/driver_signin_screen.dart';
import 'package:first_bus_project/student/auth/student_signin_screen.dart';
import 'package:first_bus_project/widgets/custom_button.dart';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/welcome.png',
                height: screenHeight * 0.6,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              SizedBox(height: screenHeight * 0.02),
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "Let's find your bus\n with just a tap.",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: screenHeight * 0.04,
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              CustomButton(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StudentSignInScreen(),
                    ),
                  );
                },
                text: "I'm a Student",
              ),
              SizedBox(height: screenHeight * 0.02),
              CustomButton(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DriverSignInScreen(),
                    ),
                  );
                },
                text: "I'm a Driver",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
