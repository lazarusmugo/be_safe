import 'package:be_safe/home_screen.dart';
import 'package:be_safe/views/login_view.dart';
import 'package:be_safe/views/register_view.dart';
import 'package:be_safe/views/verify_email_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      title: 'Be Safe',
      theme: ThemeData(
        textTheme: GoogleFonts.firaSansTextTheme(
            // Theme.of(context).textTheme,
            ),
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
      routes: {
        '/login/': (context) => const LoginView(),
        '/register/': (context) => const RegisterView(),
        '/verifyEmail/': (context) => const VerifyEmailView(),
        '/homescreen/': (context) => const HomeScreen(),
      },
      debugShowCheckedModeBanner: false,
    ),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                if (user.emailVerified) {
                  print('Email is Verified');

                  return const HomeScreen();
                } else {
                  return VerifyEmailView();
                }
              } else {
                return LoginView();
              }
            default:
              return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
