// ignore_for_file: must_be_immutable

import 'package:first_bus_project/models/user_model.dart';
import 'package:first_bus_project/student/menu/student_menu.dart';
import 'package:flutter/material.dart';

class StudentMapScreen extends StatefulWidget {
  UserModel userModel;
  StudentMapScreen({
    super.key,
    required this.userModel,
  });

  @override
  State<StudentMapScreen> createState() => _StudentMapScreenState();
}

class _StudentMapScreenState extends State<StudentMapScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Map'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentMenuScreen(
                    userModel: widget.userModel,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.person),
          )
        ],
      ),
    );
  }
}
