import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:fluttericon/font_awesome_icons.dart';
import 'package:uuid/uuid.dart';
import 'package:share/share.dart';

Future<String> createGroup(String groupName, String groupDescription,
    List<String> memberIds, bool isPrivate, String? password) async {
  final CollectionReference groupsCollection =
      FirebaseFirestore.instance.collection('groups');
  final User? currentUser = FirebaseAuth.instance.currentUser;

  final newGroupRef = await groupsCollection.add({
    'groupName': groupName,
    'groupDescription': groupDescription,
    'memberIds': memberIds,
    'isPrivate': isPrivate,
    'password': password,
    'creatorId': currentUser!.uid,
    'createdAt': FieldValue.serverTimestamp(),
  });
  final groupId = newGroupRef.id;
  await newGroupRef.collection('group_members').doc(currentUser!.uid).set({
    'userId': currentUser.uid,
    'username': currentUser.displayName,
    'profilePhotoUrl': currentUser.photoURL,
    'isVisible': true,
    'location': null, // replace with the user's location if available
    'visibleUntil':
        null, // replace with the expiration time of visibility if applicable
  });

  return newGroupRef.id;
}

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({Key? key}) : super(key: key);

  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _groupNameController = TextEditingController();
  final _groupDescriptionController = TextEditingController();
  final _inviteLinkController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPrivate = false;
  String groupId = '';

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final groupName = _groupNameController.text.trim();
    final groupDescription = _groupDescriptionController.text.trim();
    final password = _passwordController.text.trim();
    final uuid = const Uuid();
    final groupId = uuid.v4();
    final link = 'https://besafe.com/groups/$groupId';
    final memberIds = [FirebaseAuth.instance.currentUser!.uid];

    try {
      final groupIdResult = await createGroup(groupName, groupDescription,
          memberIds, _isPrivate, password.isNotEmpty ? password : null);

      // Save the invite link to the group in Firestore
      final groupRef =
          FirebaseFirestore.instance.collection('groups').doc(groupIdResult);
      await groupRef.update({'inviteLink': link});
      final currentUser = FirebaseAuth.instance.currentUser;
      await groupRef.collection('group_members').doc(currentUser!.uid).set({
        'isVisible': true,
        'location': null,
        'profilePhotoUrl': currentUser.photoURL,
        'userId': currentUser.uid,
        'username': currentUser.displayName,
        'visibleUntil': null,
      });
      // Pass groupId to _shareLink method
      _shareLink(groupIdResult);

      // Show a success message and pop up ShareLink dialog
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Group created successfully'),
          content: const Text('Do you want to share the group link?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.pop(context);
                _shareLink(groupIdResult);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    } catch (e) {
      // Show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create group'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _groupDescriptionController.dispose();
    _inviteLinkController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _shareLink(String groupIdResult) {
    final link = 'https://besafe.com/groups/$groupIdResult';
    final message = 'Join my group on BE SAFE!';

    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Copy Link'),
            leading: const Icon(Icons.copy),
            onTap: () {
              Clipboard.setData(ClipboardData(text: link));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copied to clipboard')),
              );
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            title: const Text('WhatsApp'),
            leading: const Icon(FontAwesome.whatsapp),
            onTap: () {
              Share.share('$message $link', subject: message);
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            title: const Text('Messaging'),
            leading: const Icon(FontAwesome.comment),
            onTap: () {
              Share.share('$message $link', subject: message);
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            title: const Text('Facebook'),
            leading: const Icon(FontAwesome.facebook),
            onTap: () {
              Share.share('$message $link', subject: message);
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            title: const Text('Email'),
            leading: const Icon(FontAwesome.folder_empty),
            onTap: () {
              Share.share('$message $link', subject: message);
              Navigator.of(context).pop();
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter group name:',
                style: TextStyle(fontSize: 16),
              ),
              TextFormField(
                controller: _groupNameController,
                decoration: const InputDecoration(
                  hintText: 'Group name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Group name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Enter group description:',
                style: TextStyle(fontSize: 16),
              ),
              TextFormField(
                controller: _groupDescriptionController,
                decoration: const InputDecoration(
                  hintText: 'Group description',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Group description is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'Private group:',
                    style: TextStyle(fontSize: 16),
                  ),
                  Checkbox(
                    value: _isPrivate,
                    onChanged: (value) {
                      setState(() {
                        _isPrivate = value!;
                      });
                    },
                  ),
                ],
              ),
              if (_isPrivate)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter group password:',
                      style: TextStyle(fontSize: 16),
                    ),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'Group password',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Group password is required';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              /* ElevatedButton(
                onPressed: _shareLink,
                child: const Text('Share Group Link'),
              ),*/
              ElevatedButton(
                onPressed: _createGroup,
                child: const Text('Create Group'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
