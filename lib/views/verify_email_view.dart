import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({super.key});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Verification'),
        backgroundColor: Colors.purple,
        centerTitle: true,
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        decoration: const BoxDecoration(
            gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple,
            Colors.blue,
          ],
        )),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /* const SizedBox(
              height: 5,
              
            ),*/
            const Text(
              'Please verify your email address:',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 50),
            TextButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                await user?.sendEmailVerification();
              },
              child: const Text(
                'Send Email Verification Link',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login/', (route) => false);
              },
              child: const Text('Go back to Login ',
                  style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}
