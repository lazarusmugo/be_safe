import 'package:be_safe/groups/join_group.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../groups/create_group_screen.dart';
import '../groups/groups_chat_screen.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({Key? key}) : super(key: key);

  @override
  _ChatsPageState createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _searchQuery = '';
    });
  }

  void _clearSearchQuery() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
    });
  }

  List<QueryDocumentSnapshot> _performSearch(
      List<QueryDocumentSnapshot> groups) {
    if (_searchQuery.isEmpty) {
      return groups;
    }

    List<QueryDocumentSnapshot> matchingGroups = [];

    for (var group in groups) {
      if (group['groupName']
          .toLowerCase()
          .contains(_searchQuery.toLowerCase())) {
        matchingGroups.add(group);
      }
    }

    return matchingGroups;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserUid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search for groups...',
                  border: InputBorder.none,
                ),
              )
            : const Text('Chats'),
        backgroundColor: Colors.blue,
        centerTitle: true,
        actions: _buildActions(),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .where('memberIds', arrayContains: currentUserUid)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final groups = _performSearch(snapshot.data!.docs);
          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return ListTile(
                title: Text(group['groupName']),
                subtitle: Text(group['groupDescription']),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupChatScreen(groupId: group.id),
                    ),
                  );
                },
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

  List<Widget> _buildActions() {
    if (_isSearching) {
      return [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: _clearSearchQuery,
        ),
      ];
    } else {
      return [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _startSearch,
        ),
        IconButton(
          icon: const Icon(Icons.group_add),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => JoinGroupPage()),
            );
          },
        ),
      ];
    }
  }
}
