import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_group_screen.dart';
import 'package:intl/intl.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;

  const GroupChatScreen({Key? key, required this.groupId}) : super(key: key);

  @override
  _GroupChatScreenState createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Chat'),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('groups')
                  .doc(widget.groupId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Something went wrong');
                }

                if (!snapshot.hasData) {
                  return const Text('Loading...');
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final message = snapshot.data!.docs[index];
                    return ListTile(
                      title: Text(message['text']),
                      subtitle: Text(
                        DateFormat('MMM d, h:mm a')
                            .format(message['timestamp'].toDate()),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextFormField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  _sendMessage();
                },
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('messages')
          .add({
        'text': text,
        'timestamp': Timestamp.now(),
      });
      _messageController.clear();
    }
  }
}
