import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LogoutPage extends StatelessWidget {
  void _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Logout'),
      ),
      body: Center(
        child: ElevatedButton(
          child: Text('Logout'),
          onPressed: () {
            _logout();
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
