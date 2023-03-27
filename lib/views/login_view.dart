import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _email;
  late final TextEditingController _password;
  bool _rememberMe = false;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    _loadRememberMeStatus();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _saveUserCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
    await prefs.setString('password', password);
  }

  void _deleteUserCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('email');
    prefs.remove('password');
  }

  void _loadRememberMeStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('rememberMe') ?? false;
      if (_rememberMe) {
        _email.text = prefs.getString('email') ?? '';
        _password.text = prefs.getString('password') ?? '';
      }
    });
  }

  void _saveRememberMeStatus() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('rememberMe', _rememberMe);
    prefs.setString('email', _email.text);
    prefs.setString('password', _password.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Welcome to BE-SAFE',
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
          ),
        ),
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
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value!;
                            _saveRememberMeStatus();
                          });
                        },
                      ),
                      const Text(
                        'Remember me',
                        style: TextStyle(color: Colors.grey, fontSize: 20),
                      ),
                    ],
                  ),
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        final email = _email.text;
                        final password = _password.text;
                        try {
                          final userCredential = await FirebaseAuth.instance
                              .signInWithEmailAndPassword(
                            email: email,
                            password: password,
                          );
                          print(userCredential);
                          if (_rememberMe) {
                            _saveUserCredentials(email, password);
                          } else {
                            _deleteUserCredentials();
                          }
                          Navigator.of(context).pushNamedAndRemoveUntil(
                              '/homescreen/', (route) => false);
                        } on FirebaseAuthException catch (e) {
                          if (e.code == 'user-not-found') {
                            print('User not found');
                          } else if (e.code == 'wrong-password') {
                            print('wrong password');
                          } else {
                            print('Error: ${e.toString()}');
                          }
                        }
                      },
                      child: const Text(
                        'Login',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                  Column(
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                              '/register/', (route) => false);
                        },
                        child: const Text('Dont have an account? Register Here',
                            textAlign: TextAlign.right,
                            style:
                                TextStyle(color: Colors.white, fontSize: 20)),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                              '/police_registration/', (route) => false);
                        },
                        child: const Text('Login as a Police',
                            style:
                                TextStyle(color: Colors.white, fontSize: 20)),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
