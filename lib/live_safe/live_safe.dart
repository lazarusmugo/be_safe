import 'dart:async';
import 'package:be_safe/live_safe/bus_station_card.dart';
import 'package:be_safe/live_safe/fcm_service.dart';
import 'package:be_safe/live_safe/hospital_card.dart';
import 'package:be_safe/live_safe/hotels_card.dart';
import 'package:be_safe/live_safe/pharmacy_card.dart';
import 'package:be_safe/live_safe/police_station_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../views/maps_view.dart';
import 'package:shake/shake.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(LiveSafe());
}

class LiveSafe extends StatefulWidget {
  @override
  State<LiveSafe> createState() => _LiveSafeState();
}

class _LiveSafeState extends State<LiveSafe> {
  bool emergencyMode = false;
  int shakeCount = 0;
  DateTime? lastShakeTime;
  ShakeDetector? shakeDetector;

  @override
  void initState() {
    super.initState();

    startShakeDetector();
    // requestPermission();
    requestNotificationPermission();
    FirebaseMessaging.instance.requestPermission();
    Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    sendNotificationToDevice();
    // Set up a method to handle incoming messages when the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received message in foreground: ${message.notification?.title}');
    });
    // Set up a method to handle incoming messages when the app is in the background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    // Set up a method to handle incoming messages when the app is terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print(
          'Received message in terminated state: ${message.notification?.title}');
    });
  }

  Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    print("Handling a background message: ${message.messageId}");
  }

  Future<void> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    final fcmToken = await FirebaseMessaging.instance.getToken();
    print(fcmToken);
    if (status.isGranted) {
      print('Notification permission granted.');
    } else {
      final result = await Permission.notification.request();
      if (result.isGranted) {
        print('Notification permission granted.');
      } else {
        print('Notification permission denied.');
      }
    }
  }

  Future<void> sendNotificationToDevice() async {
    FirebaseMessaging _fcm = FirebaseMessaging.instance;
    _fcm.setAutoInitEnabled(true);
    String? fcmToken = await _fcm.getToken();

    if (fcmToken != null) {
      print("FCM token: $fcmToken");
      try {
        // ignore: prefer_const_constructors
        var android = AndroidNotificationDetails(
          'channelId',
          'channelName',
          // 'channelDescription',
          importance: Importance.high,
          priority: Priority.high,
        );

        var platform = NotificationDetails(android: android);

        _fcm.sendMessage(
          to: fcmToken,
          data: {
            'title': 'Test',
            'body': 'Test',
          },
        );
        await FlutterLocalNotificationsPlugin().show(
          0,
          'Test notification',
          'This is a test notification',
          platform,
        );
        print('Notification sent successfully to device with token $fcmToken');
      } catch (e) {
        print(
            'Error sending notification to device with token $fcmToken: ${e.toString()}');
      }
    } else {
      print('Unable to retrieve FCM token');
    }
  }

  void startShakeDetector() {
    shakeDetector = ShakeDetector.autoStart(
      shakeThresholdGravity: 5,
      onPhoneShake: () {
        activateEmergencyMode();
      },
    );
  }

  void activateEmergencyMode() async {
    setState(() {
      emergencyMode = true;
      shakeCount = 0;
      sendNotificationToDevice();
    });
    // Execute code to activate emergency mode here
    // ...

    // Get the user's token
    final User? user = FirebaseAuth.instance.currentUser;
    final String? token = await FirebaseMessaging.instance.getToken();
    if (user != null) {
      print('Current user ID: ${user.uid}');
      print('Token: $token');
    }

    // Add the user's token to the "user_tokens" subcollection
    try {
      await FirebaseFirestore.instance
          .collection('user_tokens')
          .doc(user?.uid)
          .set({'token': token});
      print('created collection');
    } catch (e) {
      print('Error adding user token: $e');
    }
    sendNotificationToDevice();
    void checkEmergencyModeAndSendNotifications(
        String userId, String location) {
      if (emergencyMode == true) {}
    }
  }

  void stopEmergencyMode() {
    setState(() {
      emergencyMode = false;
    });
    // Execute code to stop emergency mode here
    // ...
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BE SAFE'),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Column(children: [
        Container(
          height: 100,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: const [
              PoliceStationCard(onMapFunction: openMap),
              Hospital(onMapFunction: openMap),
              BusStationCard(onMapFunction: openMap),
              PharmacyCard(onMapFunction: openMap),
              HotelsCard(onMapFunction: openMap)
            ],
          ),
        ),
        Container(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Expanded(
            child: MapsView(
              key: UniqueKey(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                emergencyMode = !emergencyMode;
              });
              if (emergencyMode) {
                activateEmergencyMode();
              } else {
                stopEmergencyMode();
              }
            },
            child: emergencyMode
                ? const Text('STOP EMERGENCY MODE')
                : const Text('EMERGENCY MODE'),
            style: ElevatedButton.styleFrom(
              backgroundColor: emergencyMode ? Colors.red : Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ]),
    );
  }

  static Future<void> openMap(String location) async {
    String googleUrl = 'https://www.google.com/maps/search/$location';
    final Uri url = Uri.parse(googleUrl);

    try {
      await launchUrl(url);
    } catch (e) {
      Fluttertoast.showToast(
          msg: "Something went wrong! Call emergency numbers.");
    }
  }
}
