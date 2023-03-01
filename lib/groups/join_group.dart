import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JoinGroupPage extends StatefulWidget {
  @override
  _JoinGroupPageState createState() => _JoinGroupPageState();
}

class _JoinGroupPageState extends State<JoinGroupPage> {
  final _formKey = GlobalKey<FormState>();
  final _inviteLinkController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPrivate = false;
  late String _groupName;
  late String _groupDescription;
  late String _groupId;

  void _joinGroup() async {
    setState(() {
      _isLoading = true;
    });

    // Get user ID
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;

    // Get group document from Firestore
    final groupDocs = await FirebaseFirestore.instance
        .collection('groups')
        .where('inviteLink', isEqualTo: _inviteLinkController.text)
        .limit(1)
        .get();
    final groupDoc = groupDocs.docs.isNotEmpty ? groupDocs.docs.first : null;

    // Check if group exists
    if (groupDoc == null) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group not found'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Get group data
    final groupData = groupDoc.data();
    _groupName = groupData.containsKey('name') ? groupData['name'] : '';
    _groupDescription =
        groupData.containsKey('description') ? groupData['description'] : '';
    _groupId = groupDoc.id ?? '';
    _isPrivate =
        groupData.containsKey('isPrivate') ? groupData['isPrivate'] : false;

    // Check if group is private and requires password
    if (_isPrivate) {
      if (_passwordController.text.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter the group password'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
      final password =
          groupData.containsKey('password') ? groupData['password'] : '';
      if (_passwordController.text != password) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incorrect group password'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
    }

    // Add user to group members
    final batch = FirebaseFirestore.instance.batch();
    final groupRef =
        FirebaseFirestore.instance.collection('groups').doc(_groupId);
    batch.update(groupRef, {
      'memberIds': FieldValue.arrayUnion([userId])
    });

    // Commit batch write
    batch.commit().then((_) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Joined $_groupName group'),
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.of(context).pop();
    }).catchError((error) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error joining group: $error'),
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Group'),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _inviteLinkController,
                  decoration: const InputDecoration(labelText: 'Invite Link'),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter an invite link';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _passwordController,
                  decoration:
                      const InputDecoration(labelText: 'Group Password'),
                  obscureText: true,
                  enabled: _isPrivate,
                  validator: (value) {
                    if (_isPrivate && (value?.isEmpty ?? true)) {
                      return 'Please enter the group password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _isLoading ? null : _joinGroup,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Join Group'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
