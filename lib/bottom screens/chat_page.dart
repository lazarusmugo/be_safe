import 'package:flutter/material.dart';

class ChatsPage extends StatelessWidget {
  const ChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Chats'),
          backgroundColor: Colors.blue,
          centerTitle: true,
        ),
        body: const Center(
            child: Text(
          'Chats',
          style: TextStyle(color: Colors.blue, fontSize: 20),
        )));
  }
}
