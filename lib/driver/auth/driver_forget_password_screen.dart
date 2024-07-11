// ignore_for_file: use_build_context_synchronously

import 'package:first_bus_project/services/auth_service.dart';
import 'package:first_bus_project/widgets/custom_button.dart';
import 'package:first_bus_project/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';

class DriverForgetPasswordScreen extends StatefulWidget {
  const DriverForgetPasswordScreen({super.key});

  @override
  State<DriverForgetPasswordScreen> createState() =>
      _DriverForgetPasswordScreenState();
}

class _DriverForgetPasswordScreenState
    extends State<DriverForgetPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    _emailController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _forgetPasswordSendLink({required String email}) async {
    if (_formKey.currentState!.validate()) {
      bool isRegistered = await _authService.isUserRegistered(email);
      if (isRegistered) {
        await _authService.sendPasswordResetEmail(email);
        _showResetPasswordDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user registered with this email.')),
        );
      }
    }
  }

  void _showResetPasswordDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Column(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 80,
              ),
              SizedBox(
                width: 20,
              ),
              Text(
                "Check your email!",
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
              )
            ],
          ),
          actions: [
            TextButton(
              child: const Text(
                "Resend Link",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _forgetPasswordSendLink(email: _emailController.text);
              },
            ),
            TextButton(
              child: const Text(
                "Close",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text(
          'Forget Password',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0XFF419A95),
        foregroundColor: Colors.white,
      ),
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
              children: [
                Image.asset(
                  "assets/logo.png",
                  height: screenHeight * 0.3,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: screenHeight * 0.025),
                    Text(
                      'A link will be sent to your registered email to forget your Password',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: screenWidth * 0.04,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.025),
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
                            RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value);
                        if (!isValidEmail) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: screenHeight * 0.025),
                    SizedBox(
                      height: screenHeight * 0.04,
                    ),
                    CustomButton(
                      onTap: () {
                        _forgetPasswordSendLink(email: _emailController.text);
                      },
                      text: 'Send',
                    ),
                    SizedBox(
                      height: screenHeight * 0.1,
                    ),
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
