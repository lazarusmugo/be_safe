import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _imagePicker = ImagePicker();
  XFile? _image;
  bool _isEditing = false;
  FocusNode _usernameFocusNode = FocusNode();
  late String imageUrl;

  Future<void> _pickImage() async {
    final pickedImage =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _image = pickedImage;
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return null;
    }

    final ref = firebase_storage.FirebaseStorage.instance
        .ref('profile_images/${user.uid}.jpg');
    final metadata =
        firebase_storage.SettableMetadata(contentType: 'image/jpeg');

    final uploadTask = ref.putFile(image, metadata);
    final snapshotTask = uploadTask.whenComplete(() {});
    final snapshot = await snapshotTask;

    return await snapshot.ref.getDownloadURL();
  }

  Future<void> _submitForm() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (username.isEmpty && email.isEmpty && phone.isEmpty && _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No changes made')),
      );
      return;
    }

    setState(() {
      _isEditing = false;
    });

    try {
      String? imageUrl;

      if (_image != null) {
        imageUrl = await _uploadImage(File(_image!.path));
      }

      final userData = {
        'username': username,
        'email': email,
        'phone': phone,
      };

      if (imageUrl != null) {
        userData['imageUrl'] = imageUrl;
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
            userData,
            SetOptions(merge: true),
          );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('An error occurred while updating your profile: $error'),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).get().then(
        (doc) {
          if (doc.exists) {
            final userData = doc.data() as Map<String, dynamic>;
            setState(() {
              _usernameController.text = userData['username'] ?? '';
              _emailController.text = user.email ?? '';
              _phoneController.text = userData['phone'] ?? '';
              imageUrl = userData['imageUrl'] ?? '';
            });
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('You need to be signed in to view the profile page'),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = true;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _isEditing ? _pickImage : null,
              child: CircleAvatar(
                radius: 80,
                backgroundColor: Colors.grey[300],
                /* backgroundImage: _image == null
                    ? (user.photoURL != null
                            ? NetworkImage(user.photoURL!)
                            : const AssetImage('assets/default_user.png'))
                        as ImageProvider<Object>
                    : FileImage(File(_image!.path)),*/
                backgroundImage: imageUrl != null && imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,

              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              focusNode: _usernameFocusNode,
              decoration: const InputDecoration(labelText: 'Username'),
              enabled: _isEditing,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              enabled: false,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              enabled: _isEditing,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isEditing ? _submitForm : null,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
