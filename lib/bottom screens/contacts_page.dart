import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Colors.blue,
          elevation: 0,
        ),
        body: Column(children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                padding: EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 2.0),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: (emergencyContacts.isEmpty)
                    ? const Center(
                        child: Text("No emergency contacts added yet."),
                      )
                    : ListView.builder(
                        itemCount: emergencyContacts.length,
                        itemBuilder: (BuildContext context, int index) {
                          Uint8List? image = emergencyContacts[index].photo;
                          String num = (emergencyContacts[index]
                                  .phones
                                  .isNotEmpty)
                              ? (emergencyContacts[index].phones.first.number)
                              : "--";
                          return ListTile(
                            leading: (emergencyContacts[index].photo == null)
                                ? const CircleAvatar(child: Icon(Icons.person))
                                : CircleAvatar(
                                    backgroundImage: MemoryImage(image!)),
                            title: Text(
                                "${emergencyContacts[index].name.first} ${emergencyContacts[index].name.last}"),
                            subtitle: Text(num),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () async {
                                    // Show a form to add additional details of the contact
                                    // when the button is clicked
                                    Contact? contactDetails =
                                        await showDialog<Contact>(
                                      context: context,
                                      builder: (_) => AddContactDialog(
                                        contact: emergencyContacts[index],
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.add),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    _removeEmergencyContact(
                                        emergencyContacts[index]);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 2.0),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                padding: EdgeInsets.all(20.0),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .collection('emergencyContacts')
                      .snapshots(),
                  builder: (BuildContext context,
                      AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.hasError) {
                      return const Text('Something went wrong');
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text('Loading');
                    }
                    if (snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text("No emergency contacts added yet."),
                      );
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (BuildContext context, int index) {
                        final name = snapshot.data!.docs[index]['name']
                                ['first'] +
                            " " +
                            snapshot.data!.docs[index]['name']['last'];
                        final phone = (snapshot.data!.docs[index]['phone'] !=
                                    null &&
                                snapshot.data!.docs[index]['phone'].isNotEmpty)
                            ? snapshot.data!.docs[index]['phone']
                            : '--';

                        final relationship =
                            (snapshot.data!.docs[index]['relationship'] != null)
                                ? snapshot.data!.docs[index]['relationship']
                                : '--';

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            side: BorderSide(
                              color: Colors.grey,
                              width: 1.0,
                            ),
                          ),
                          child: ListTile(
                            title: Text(name),
                            subtitle: Text("$phone | $relationship"),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                // Remove the contact from Firestore
                                FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(FirebaseAuth.instance.currentUser!.uid)
                                    .collection('emergencyContacts')
                                    .doc(snapshot.data!.docs[index].id)
                                    .delete();
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 80.0),
            child: FloatingActionButton(
              onPressed: () => _showContactsList(context),
              child: const Icon(Icons.add),
            ),
          ),
        ]));
  }
}

class AddContactDialog extends StatefulWidget {
  final Contact contact;
  const AddContactDialog({required this.contact});

  @override
  _AddContactDialogState createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<AddContactDialog> {
  late String _relationship;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _relationship = '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Contact Details"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: const InputDecoration(hintText: "Relationship"),
            onChanged: (value) {
              _relationship = value;
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () async {
            setState(() {
              _isSaving = true;
            });

            try {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .collection('emergencyContacts')
                  .add({
                'name': {
                  'first': widget.contact.name.first,
                  'last': widget.contact.name.last,
                },
                'phone': widget.contact.phones.first.number,
                'relationship': _relationship
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contact saved successfully!'),
                  duration: Duration(seconds: 2),
                ),
              );
            } catch (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to save contact: $error'),
                  duration: Duration(seconds: 2),
                ),
              );
            } finally {
              setState(() {
                _isSaving = false;
              });
            }

            Navigator.of(context).pop(widget.contact);
          },
          child: _isSaving
              ? const CircularProgressIndicator()
              : const Text("Save"),
        ),
      ],
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
