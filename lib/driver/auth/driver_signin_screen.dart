// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:first_bus_project/driver/auth/driver_forget_password_screen.dart';
import 'package:first_bus_project/driver/auth/driver_signup_screen.dart';
import 'package:first_bus_project/driver/home/driver_map_screen.dart';
import 'package:first_bus_project/models/route_model.dart';
import 'package:first_bus_project/models/user_model.dart';
import 'package:first_bus_project/services/auth_service.dart';
import 'package:first_bus_project/services/routes_services.dart';
import 'package:first_bus_project/widgets/custom_button.dart';
import 'package:first_bus_project/widgets/custom_textfield.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class DriverSignInScreen extends StatefulWidget {
  const DriverSignInScreen({super.key});

  @override
  State<DriverSignInScreen> createState() => _DriverSignInScreenState();
}

class _DriverSignInScreenState extends State<DriverSignInScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  final AuthService _authService = AuthService();
  final RoutesService _routesService = RoutesService();
  bool _showPassword = false;
  bool _isLoading = false;

  @override
  void initState() {
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login({required String email, required String password}) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      UserModel? userModel = await _authService.login(
        context: context,
        email: email,
        password: password,
      );

      if (userModel == null) {
        setState(() {
          _isLoading = false;
        });
      }

      User? firebaseUser = FirebaseAuth.instance.currentUser;

      final BusRouteModel busRouteModel =
          await _routesService.getBusRoute(context, firebaseUser!.uid);

      if (userModel != null) {
        setState(() {
          _isLoading = false;
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DriverMapScreen(
              userModel: userModel,
              busRouteModel: busRouteModel,
            ),
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: screenHeight * 0.02,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: screenHeight * 0.08),
                IconButton(
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                  icon: Icon(
                    Icons.arrow_back_ios_new_outlined,
                    color: const Color(0XFF419A95),
                    size: screenWidth * 0.08,
                  ),
                ),
                SizedBox(height: screenHeight * 0.04),
                Text(
                  "Welcome Back\nDriver!",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: screenHeight * 0.04,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: screenHeight * 0.1),
                    CustomFields(
                      icon: const Icon(
                        Icons.email,
                        color: Colors.grey,
                      ),
                      isPassword: false,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      text: 'Email',
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter your email';
                        }
                        bool isValidEmail =
                            RegExp(r'^[\w-\.]+@gmail\.com$').hasMatch(value);

                        if (!isValidEmail) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: screenHeight * 0.025),
                    CustomFields(
                      icon: IconButton(
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _showPassword = !_showPassword;
                          });
                        },
                      ),
                      isPassword: !_showPassword,
                      controller: _passwordController,
                      keyboardType: TextInputType.visiblePassword,
                      text: 'Password',
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: screenHeight * 0.025),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DriverForgetPasswordScreen(),
                          ),
                        );
                      },
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.0425,
                            color: const Color(0xff281537),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.0375),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : CustomButton(
                            onTap: () {
                              _login(
                                email: _emailController.text.trim(),
                                password: _passwordController.text,
                              );
                            },
                            text: 'Sign In',
                          ),
                    SizedBox(height: screenHeight * 0.15),
                    Align(
                      alignment: Alignment.center,
                      child: Text.rich(
                        TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: screenWidth * 0.045,
                          ),
                          children: [
                            TextSpan(
                              text: "Sign Up",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: screenWidth * 0.05,
                                color: const Color(0XFF419A95),
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const DriverSignUpScreen(),
                                    ),
                                  );
                                },
                            )
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.025),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
