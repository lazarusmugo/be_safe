/*import 'package:be_safe/views/login_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../groups/create_group_screen.dart';
import '../groups/groups_chat_screen.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _ChatsPageState createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const LoginView();
    }

    Query groupQuery = FirebaseFirestore.instance
        .collection('groups')
        .where('memberIds', arrayContains: currentUser.uid);

    if (_searchQuery.isNotEmpty) {
      groupQuery = groupQuery.where('inviteLink', arrayContains: _searchQuery);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        backgroundColor: Colors.blue,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
              });
            },
            icon: const Icon(Icons.clear),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blueGrey[900],
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(
                  color: Colors.grey[600]!,
                  width: 1.0,
                ),
              ),
              child: TextField(
                style: TextStyle(color: Colors.white),
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search groups',
                  hintStyle: TextStyle(color: Colors.white),
                  prefixIcon: Icon(Icons.search, color: Colors.white),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase().trim();
                  });
                },
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .where('memberIds', arrayContains: currentUser.uid)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final groups = snapshot.data!.docs;
          if (groups.isEmpty) {
            return const Center(child: Text('No groups found'));
          }
          final filteredGroups = groups.where((group) {
            final inviteLinks = List<String>.from(group['inviteLink']);
            return inviteLinks
                .any((link) => link.toLowerCase().contains(_searchQuery));
          }).toList();
          if (filteredGroups.isEmpty) {
            return const Center(child: Text('No groups found'));
          }
          return ListView.builder(
            itemCount: filteredGroups.length,
            itemBuilder: (context, index) {
              final group = filteredGroups[index];
              return Card(
                child: ListTile(
                  title: Text(
                    group['groupName'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                  subtitle: Text(group['groupDescription']),
                  trailing: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          String link = '';
                          return AlertDialog(
                            title: const Text('Join Group'),
                            content: TextFormField(
                              decoration: const InputDecoration(
                                hintText: 'Enter invite link',
                              ),
                              onChanged: (value) {
                                link = value;
                              },
                            ),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  // Update Firestore with the current user's id
                                  FirebaseFirestore.instance
                                      .collection('groups')
                                      .doc(group.id)
                                      .update({
                                    'memberIds':
                                        FieldValue.arrayUnion([currentUser.uid])
                                  });

                                  Navigator.pop(context);
                                },
                                child: const Text('Join'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: const Text('Join Group'),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            GroupChatScreen(groupId: group.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
          );
        },
        label: const Text('Create Group'),
        icon: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Theme.of(context).canvasColor,
        elevation: 0,
        child: const SizedBox(
          height: kBottomNavigationBarHeight,
        ),
      ),
    );
  }
}

*/