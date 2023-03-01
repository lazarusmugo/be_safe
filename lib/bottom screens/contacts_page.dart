import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({Key? key}) : super(key: key);

  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  dynamic _contacts = {};

  @override
  void initState() {
    getContacts();
    super.initState();
  }

  Future<void> getContacts() async {
    if (mounted) {
      Iterable<Contact>? contacts =
          await ContactsService.getContacts(withThumbnails: false);
      setState(() {
        _contacts = contacts;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(_contacts.toString())),
    );
  }
}
