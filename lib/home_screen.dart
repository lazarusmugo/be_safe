import 'dart:collection';
import 'package:be_safe/bottom%20screens/chat_page.dart';
import 'package:be_safe/bottom%20screens/contacts_page.dart';
import 'package:be_safe/bottom%20screens/profile_page.dart';
import 'package:be_safe/bottom%20screens/settings_page.dart';
import 'package:be_safe/live_safe/live_safe.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final screens = [
    LiveSafe(),
    const ChatsPage(),
    const Contacts(),
    const ProfilePage(),
    const SettingPage(),
  ];

  int index = 0;
  //final navigationKey = GlobalKey<CurvedNavigationBarState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: screens[index],
      bottomNavigationBar: Theme(
        data: Theme.of(context)
            .copyWith(iconTheme: const IconThemeData(color: Colors.white)),
        child: CurvedNavigationBar(
            items: const [
              Icon(Icons.home, size: 30),
              Icon(Icons.chat, size: 30),
              Icon(Icons.contacts, size: 30),
              Icon(Icons.person, size: 30),
              Icon(Icons.settings, size: 30),
            ],
            buttonBackgroundColor: Colors.blue,
            color: Colors.blue,
            backgroundColor: Colors.white,
            height: 60,
            animationCurve: Curves.easeInOut,
            animationDuration: const Duration(milliseconds: 500),
            index: index,
            onTap: (index) => setState(() => this.index = index)),
      ),
    );
  }
}
