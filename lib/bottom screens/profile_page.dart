import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: Colors.blue,
          centerTitle: true,
        ),
        body: const Center(
            child: Text(
          'Profile',
          style: TextStyle(color: Colors.blue, fontSize: 20),
        )));
  }
}
