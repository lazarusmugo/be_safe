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
        title: const Text(
          'Email Verification',
          style: TextStyle(
              color: Colors.white, fontSize: 35, fontFamily: 'Ubuntu'),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(200))),
        backgroundColor: Colors.blue,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(150),
          child: SizedBox(),
        ),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        decoration: const BoxDecoration(
            gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.blue,
          ],
        )),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /* const SizedBox(
              height: 5,
              
            ),*/

            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                await user?.sendEmailVerification();
              },
              child: const Text(
                'Send Email Verification Link',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
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
