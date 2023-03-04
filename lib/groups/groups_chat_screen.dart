import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;

  const GroupChatScreen({Key? key, required this.groupId}) : super(key: key);

  @override
  _GroupChatScreenState createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _messageController = TextEditingController();
  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      // get current user's information
      final currentUser = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();
      final username = currentUser['username'] as String?;
      final imageUrl = currentUser['imageUrl'] as String?;
      if (username != null && imageUrl != null) {
        // add null check
        FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('messages')
            .add({
          'text': text,
          'timestamp': Timestamp.now(),
          'username': username,
          'imageUrl': imageUrl,
          'userId': FirebaseAuth.instance.currentUser!.uid,
        });
        _messageController.clear();
      }
    }
  }

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
                    final message = snapshot.data!.docs[index].data()
                        as Map<String, dynamic>;

                    final senderUsername = message['username'];
                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(senderUsername)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          // Handle the error state
                          return Center(
                              child: Text(
                                  "An error occurred while fetching data"));
                        } else if (!snapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }
                        String? senderProfileImage;
                        if (snapshot.hasData && snapshot.data != null) {
                          final data = snapshot.data!.data();
                          if (data != null) {
                            final senderProfileImage =
                                (data as Map<String, dynamic>)['imageUrl'];
                            print(senderProfileImage);
                          }
                        }

                        // add the null check here
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(senderProfileImage ??
                                ''), // provide a default value if it is null
                          ),
                          title: Text(message['username'] ?? ''),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(message['text'] ?? ''),
                              Text(
                                DateFormat('MMM d, h:mm a').format(
                                    (message['timestamp'] as Timestamp)
                                        .toDate()),
                              ),
                            ],
                          ),
                        );
                      },
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
}
