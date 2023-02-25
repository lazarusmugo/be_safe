import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

Future<String> createGroup(String groupName, String groupDescription) async {
  final CollectionReference groupsCollection =
      FirebaseFirestore.instance.collection('groups');
  final User? currentUser = FirebaseAuth.instance.currentUser;

  final newGroupRef = await groupsCollection.add({
    'groupName': groupName,
    'groupDescription': groupDescription,
    'memberIds': [currentUser!.uid],
  });

  return newGroupRef.id;
}

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _groupNameController = TextEditingController();
  final _groupDescriptionController = TextEditingController();
  final _inviteLinkController = TextEditingController();

  Future<void> _createGroup() async {
    final groupName = _groupNameController.text.trim();
    final groupDescription = _groupDescriptionController.text.trim();
    final uuid = Uuid();
    final groupId = uuid.v4();
    final link = 'https://example.com/groups/$groupId';

    if (groupName.isEmpty) {
      // TODO: Show error message that group name is required
      return;
    }

    final groupIdResult = await createGroup(groupName, groupDescription);

    // Save the invite link to the group in Firestore
    final groupRef =
        FirebaseFirestore.instance.collection('groups').doc(groupIdResult);
    await groupRef.update({'inviteLink': link});

    // Navigate back to the previous screen
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _groupDescriptionController.dispose();
    _inviteLinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Padding(
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
            ),
            const SizedBox(height: 16),
            const Text(
              'Invite link:',
              style: TextStyle(fontSize: 16),
            ),
            TextFormField(
              controller: _inviteLinkController,
              decoration: InputDecoration(
                hintText: 'https://example.com/groups/group_id',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _createGroup();
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
