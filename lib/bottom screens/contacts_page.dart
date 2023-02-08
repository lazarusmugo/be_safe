import 'package:flutter/material.dart';

class ContactsPage extends StatelessWidget {
  const ContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Contacts'),
          backgroundColor: Colors.blue,
          centerTitle: true,
        ),
        body: const Center(
            child: Text(
          'Contacts',
          style: TextStyle(color: Colors.blue, fontSize: 20),
        )));
  }
}
