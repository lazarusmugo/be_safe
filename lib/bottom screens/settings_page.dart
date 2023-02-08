import 'package:flutter/material.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Settings',
          style: TextStyle(color: Colors.blue, fontSize: 20),
        ),
      ),
    );
  }
}
