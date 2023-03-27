import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Register',
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
        decoration: const BoxDecoration(
            gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.blue,
          ],
        )),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Form(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 5,
                  ),
                  TextFormField(
                    style: const TextStyle(color: Colors.black, fontSize: 20),
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: InputDecoration(
                      fillColor: Colors.blue,
                      hintText: 'Enter your email',
                      hintStyle: const TextStyle(
                        fontSize: 20.0,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    style: const TextStyle(color: Colors.black, fontSize: 20),
                    controller: _password,
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      hintStyle: const TextStyle(
                        fontSize: 20.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        final email = _email.text;
                        final password = _password.text;

                        try {
                          final userCredential = await FirebaseAuth.instance
                              .createUserWithEmailAndPassword(
                            email: email,
                            password: password,
                          );
                          print(userCredential);
                        } on FirebaseAuthException catch (e) {
                          if (e.code == 'weak-password') {
                            print('weak password');
                          } else if (e.code == 'email-already-in-use') {
                            print('email already in use');
                          } else if (e.code == 'invalid-email') {
                            print('invalid email');
                          }
                        }
                      },
                      child: const Text(
                        'Register',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                  Center(
                    child: Column(
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                                '/login/', (route) => false);
                          },
                          child: const Text(
                            'Already Registered? Login here',
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                                '/verifyEmail/', (route) => false);
                          },
                          child: const Text('Verify your email ',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 20)),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
