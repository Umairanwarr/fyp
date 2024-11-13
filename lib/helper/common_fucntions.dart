// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class CommonFunctions {
  static Future<String?> uploadImageToFirebase({
    required File imageFile,
    required String path,
    required BuildContext context,
  }) async {
    try {
      final storageRef = FirebaseStorage.instance.ref();
      final String uniqueId = const Uuid().v4();
      final imagesRef = storageRef.child('$path/$uniqueId.png');
      await imagesRef.putFile(imageFile);
      final downloadUrl = await imagesRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
      return null;
    }
  }
}
