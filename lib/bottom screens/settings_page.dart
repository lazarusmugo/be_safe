import 'package:be_safe/views/log_out_page.dart';
import 'package:flutter/material.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Center(
            child: Text(
              'Settings',
              style: TextStyle(color: Colors.blue, fontSize: 20),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LogoutPage()),
              );
            },
            child: const Text('Go to logout page'),
          ),
        ],
      ),
    );
  }
}
