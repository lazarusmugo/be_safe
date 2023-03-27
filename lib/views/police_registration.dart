import 'package:be_safe/live_safe/police_maps.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PoliceRegistrationPage extends StatefulWidget {
  const PoliceRegistrationPage({Key? key}) : super(key: key);

  @override
  _PoliceRegistrationPageState createState() => _PoliceRegistrationPageState();
}

class _PoliceRegistrationPageState extends State<PoliceRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Police Registration',
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                try {
                                  final userCredential = await FirebaseAuth
                                      .instance
                                      .createUserWithEmailAndPassword(
                                    email: _emailController.text,
                                    password: _passwordController.text,
                                  );
                                  final uid = userCredential.user!.uid;
                                  final email = userCredential.user!.email!;
                                  await FirebaseFirestore.instance
                                      .collection('police')
                                      .doc(uid)
                                      .set({
                                    'email': email,
                                    'role': 'police',
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Registration successful')),
                                  );
                                } on FirebaseAuthException catch (e) {
                                  if (e.code == 'weak-password') {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'The password provided is too weak.')),
                                    );
                                  } else if (e.code == 'email-already-in-use') {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'The account already exists for that email.')),
                                    );
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Registration failed')),
                                  );
                                }
                              }
                            },
                            child: const Text('Register'),
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              try {
                                final email =
                                    'admin@example.com'; // Replace with the actual admin email
                                final password =
                                    'adminpassword'; // Replace with the actual admin password
                                final userCredential = await FirebaseAuth
                                    .instance
                                    .signInWithEmailAndPassword(
                                  email: email,
                                  password: password,
                                );
                                final uid = userCredential.user!.uid;
                                final userDoc = await FirebaseFirestore.instance
                                    .collection('police')
                                    .doc(uid)
                                    .get();
                                if (userDoc.exists &&
                                    userDoc.get('role') == 'police') {
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: (_) => PoliceMapPage()));
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Access denied')),
                                  );
                                }
                              } on FirebaseAuthException catch (e) {
                                if (e.code == 'user-not-found' ||
                                    e.code == 'wrong-password') {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Invalid credentials')),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Login failed')),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Login failed')),
                                );
                              }
                            },
                            child: const Text('Login'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 80.0),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/login/', (route) => false);
                  },
                  child: const Text(
                    'Go back to Login Page',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
