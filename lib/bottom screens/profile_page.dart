import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _imagePicker = ImagePicker();
  XFile? _image;

  bool _isLoading = false;

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
    final snapshot = await uploadTask.whenComplete(() => null);

    return await snapshot.ref.getDownloadURL();
  }

  Future<void> _submitForm() async {
    final isValid = _formKey.currentState!.validate();

    if (!isValid) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final imageUrl =
          _image != null ? await _uploadImage(File(_image!.path)) : null;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'phone': _phoneController.text.trim(),
        'imageUrl': imageUrl,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('An error occurred while updating your profile: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('You need to be logged in to view this page'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage:
                        _image != null ? FileImage(File(_image!.path)) : null,
                    child: _image == null
                        ? const Icon(Icons.camera_alt, size: 30)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter your phone number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Update Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
