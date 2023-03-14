import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class Contacts extends StatefulWidget {
  const Contacts({Key? key}) : super(key: key);

  @override
  _ContactsState createState() => _ContactsState();
}

class _ContactsState extends State<Contacts> {
  late List<Contact> contacts = [];
  List<Contact> emergencyContacts = [];

  @override
  void initState() {
    super.initState();
    getContact();
  }

  void getContact() async {
    if (await FlutterContacts.requestPermission()) {
      contacts = await FlutterContacts.getContacts(
          withProperties: true, withPhoto: true);
      setState(() {});
    }
  }

  void _addEmergencyContact(Contact contact) {
    if (!emergencyContacts.contains(contact)) {
      setState(() {
        emergencyContacts.add(contact);
      });
    }
  }

  void _removeEmergencyContact(Contact contact) {
    setState(() {
      emergencyContacts.remove(contact);
    });
  }

  void _showContactsList(BuildContext context) async {
    final List<Contact>? selectedContacts = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => ContactsList(
          contacts: contacts,
          emergencyContacts: emergencyContacts,
          onContactsSelected: (List<Contact> contacts) {
            setState(() {
              for (final contact in contacts) {
                _addEmergencyContact(contact);
              }
            });
          },
        ),
      ),
    );

    if (selectedContacts != null && selectedContacts.isNotEmpty) {
      for (final contact in selectedContacts) {
        _addEmergencyContact(contact);
      }
      _saveEmergencyContacts();
    }
  }

  void _saveEmergencyContacts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> selectedContacts = emergencyContacts
        .map((contact) =>
            "${contact.name.first} ${contact.name.last} ${contact.phones.first.number}")
        .toList();
    prefs.setStringList('emergencyContacts', selectedContacts);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Emergency Contacts",
          style: TextStyle(color: Colors.blue),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: (emergencyContacts.isEmpty)
          ? const Center(
              child: Text("No emergency contacts added yet."),
            )
          : ListView.builder(
              itemCount: emergencyContacts.length,
              itemBuilder: (BuildContext context, int index) {
                Uint8List? image = emergencyContacts[index].photo;
                String num = (emergencyContacts[index].phones.isNotEmpty)
                    ? (emergencyContacts[index].phones.first.number)
                    : "--";
                return ListTile(
                  leading: (emergencyContacts[index].photo == null)
                      ? const CircleAvatar(child: Icon(Icons.person))
                      : CircleAvatar(backgroundImage: MemoryImage(image!)),
                  title: Text(
                      "${emergencyContacts[index].name.first} ${emergencyContacts[index].name.last}"),
                  subtitle: Text(num),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      _removeEmergencyContact(emergencyContacts[index]);
                    },
                  ),
                  onTap: () {
                    if (emergencyContacts[index].phones.isNotEmpty) {
                      launch('tel: ${num}');
                    }
                  },
                );
              },
            ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 80.0),
        child: FloatingActionButton(
          onPressed: () => _showContactsList(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class ContactsList extends StatefulWidget {
  const ContactsList({
    Key? key,
    required this.contacts,
    required this.emergencyContacts,
    required this.onContactsSelected,
  }) : super(key: key);
  final List<Contact> contacts;
  final List<Contact> emergencyContacts;
  final void Function(List<Contact> contacts) onContactsSelected;

  @override
  _ContactsListState createState() => _ContactsListState();
}

class _ContactsListState extends State<ContactsList> {
  List<Contact> _selectedContacts = [];

  bool _isSelected(Contact contact) {
    return _selectedContacts.contains(contact);
  }

  void _toggleSelection(Contact contact) {
    setState(() {
      if (_isSelected(contact)) {
        _selectedContacts.remove(contact);
      } else {
        _selectedContacts.add(contact);
      }
    });
  }

  void _addToEmergencyContacts() {
    //async {
    /* for (final contact in _selectedContacts) {
      if (!widget.emergencyContacts.contains(contact)) {
        widget.emergencyContacts.add(contact);
      }
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> selectedContacts = widget.emergencyContacts
        .map((contact) =>
            "${contact.name.first} ${contact.name.last} ${contact.phones.first.number}")
        .toList();
    await prefs.setStringList('emergencyContacts', selectedContacts);
    _selectedContacts.clear();
    Navigator.of(context).pop(widget.emergencyContacts);*/
    widget.onContactsSelected(_selectedContacts);
    setState(() {
      _selectedContacts.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Contacts'),
        actions: [
          if (_selectedContacts.isNotEmpty)
            IconButton(
              onPressed: _addToEmergencyContacts,
              icon: const Icon(Icons.check),
            ),
        ],
      ),
      body: ListView.builder(
        itemCount: widget.contacts.length,
        itemBuilder: (BuildContext context, int index) {
          final contact = widget.contacts[index];
          return ListTile(
            leading: (contact.photo == null)
                ? const CircleAvatar(child: Icon(Icons.person))
                : CircleAvatar(backgroundImage: MemoryImage(contact.photo!)),
            title: Text("${contact.name.first} ${contact.name.last}"),
            subtitle: Text(
                (contact.phones.isNotEmpty) ? contact.phones.first.number : ''),
            onTap: () => _toggleSelection(contact),
            selected: _isSelected(contact),
          );
        },
      ),
    );
  }
}
