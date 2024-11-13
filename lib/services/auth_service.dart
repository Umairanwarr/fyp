// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:first_bus_project/driver/home/driver_map_screen.dart';
import 'package:first_bus_project/helper/common_fucntions.dart';
import 'package:first_bus_project/helper/constants.dart';
import 'package:first_bus_project/models/route_model.dart';
import 'package:first_bus_project/models/user_model.dart';
import 'package:first_bus_project/onboarding/onbording_screen.dart';
import 'package:first_bus_project/services/routes_services.dart';
import 'package:first_bus_project/student/home/student_map_screen.dart';
import 'package:flutter/material.dart';

User? firebaseUser = auth.FirebaseAuth.instance.currentUser;

class AuthService {
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RoutesService _routesService = RoutesService();

  Future<bool> isUserRegistered(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> checkUserAndNavigate(
      {required BuildContext context, required mounted}) async {
    await Future.delayed(const Duration(seconds: 2));

    if (firebaseUser != null) {
      UserModel? userModel = await _getUserModel(firebaseUser!.uid, context);
      if (mounted) {
        if (userModel != null) {
          _navigateToDashboard(context: context, userModel: userModel);
        } else {
          _navigateToOnboarding(context: context);
        }
      }
    } else {
      if (mounted) {
        _navigateToOnboarding(context: context);
      }
    }
  }

  Future<UserModel?> _getUserModel(String uid, BuildContext context) async {
    try {
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(uid).get();

      if (userSnapshot.exists) {
        Map<String, dynamic>? userDataMap =
            userSnapshot.data() as Map<String, dynamic>?;
        if (userDataMap != null) {
          return UserModel.fromJson(userDataMap);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('User data is null or not in the expected format.')),
      );
    }
    return null;
  }

  void _navigateToDashboard(
      {required UserModel userModel, required BuildContext context}) async {
    if (userModel.userType == 'Student') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => StudentMapScreen(
            userModel: userModel,
          ),
        ),
      );
    } else if (userModel.userType == 'Driver') {
      final BusRouteModel busRouteModel =
          await _routesService.getBusRoute(context, firebaseUser!.uid);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DriverMapScreen(
            userModel: userModel,
            busRouteModel: busRouteModel,
          ),
        ),
      );
    } else {
      _navigateToOnboarding(context: context);
    }
  }

  void _navigateToOnboarding({required BuildContext context}) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const OnbordingScreen(),
      ),
    );
  }

  Future<UserModel?> login({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      auth.UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      auth.User? firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        DocumentSnapshot userSnapshot =
            await _firestore.collection('users').doc(firebaseUser.uid).get();

        if (userSnapshot.exists) {
          Map<String, dynamic>? userDataMap =
              userSnapshot.data() as Map<String, dynamic>?;

          if (userDataMap != null) {
            UserModel userData = UserModel.fromJson(userDataMap);
            return userData;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('User data is null or not in the expected format.'),
              ),
            );
            return null;
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User data not found in Firestore.')),
          );
          return null;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Firebase user not found.')),
        );
        return null;
      }
    } on auth.FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to login: $e')),
      );
      return null;
    }
  }

  Future<void> updateUserRecord({
    required BuildContext context,
    required UserModel updatedUser,
    File? newProfileImage,
  }) async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      String? profileImageUrl = updatedUser.profileImageUrl;

      if (newProfileImage != null) {
        profileImageUrl = await CommonFunctions.uploadImageToFirebase(
          path: constProfileImageCollection,
          imageFile: newProfileImage,
          context: context,
        );
      }

      if (firebaseUser != null) {
        final userToUpdate =
            updatedUser.copyWith(profileImageUrl: profileImageUrl);
        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .update(userToUpdate.toJson());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User record updated successfully.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update user record: $e')),
      );
    }
  }

  Future<void> logout({
    required BuildContext context,
  }) async {
    try {
      await _firebaseAuth.signOut();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User logged out successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to logout: $e')),
      );
    }
  }

  Future<void> signUp({
    required BuildContext context,
    required String name,
    required String email,
    required String phone,
    required String userType,
    required String busNumber,
    required String busStop,
    required String password,
    required String selectedUniversity,
    required String profileImage,
  }) async {
    try {
      auth.UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      auth.User? firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        UserModel newUser = UserModel(
          name: name,
          email: email,
          phone: phone,
          userType: userType,
          busNumber: busNumber,
          busColor: busStop,
          universityName: selectedUniversity,
          profileImageUrl: profileImage,
        );

        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(newUser.toJson());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User signed up successfully.')),
        );
      }
    } on auth.FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign up: $e')),
      );
    }
  }
}
