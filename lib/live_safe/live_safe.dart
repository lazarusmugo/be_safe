import 'dart:async';
import 'package:be_safe/live_safe/bus_station_card.dart';
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
import 'package:location/location.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:shared_preferences/shared_preferences.dart';

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
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
      setState(() {
        emergencyMode = _prefs.getBool('emergencyMode') ?? false;
      });
    });

    startShakeDetector();
    checkEmergencyModeAndSendMessage();
    requestNotificationPermission();
    FirebaseMessaging.instance.requestPermission();
    Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
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
      _prefs.setBool('emergencyMode', true);
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

    Timer.periodic(Duration(minutes: 1), (timer) {
      sendEmergencySms();
    });
  }

  void checkEmergencyModeAndSendMessage() async {
    {
      if (emergencyMode == true) {
        Timer.periodic(Duration(seconds: 10), (timer) {
          sendEmergencySms();
        });
      }
    }
  }

  void stopEmergencyMode() {
    setState(() {
      emergencyMode = false;
      _prefs.setBool('emergencyMode', false);
    });
    // Execute code to stop emergency mode here
    // ...
  }

  void sendEmergencySms() async {
    final status = await ph.Permission.sms.request();

    if (status != ph.PermissionStatus.granted) {
      // Permission denied, handle the error
      throw Exception('SMS permission not granted');
    }
    print('permission status for smsPermission');
    final User? user = FirebaseAuth.instance.currentUser;
    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(user?.uid);
    final userSnap = await userDoc.get();
    final emergencyContacts =
        userSnap.reference.collection('emergencyContacts');
    final groups = FirebaseFirestore.instance.collection('groups');

    // Get emergency contacts phone numbers
    final contactsPhoneNumbers = await emergencyContacts.get().then(
        (snapshot) =>
            snapshot.docs.map((doc) => doc['phone'] as String).toList());

    print('contacts are $contactsPhoneNumbers');
    // Get group members phone numbers
    final groupDocs = await groups.get();
    final groupMembersPhoneNumbers = <String>{};
    final groupsUserIsMemberOf = <String>{};
    for (final groupDoc in groupDocs.docs) {
      final memberIds =
          List<String>.from(groupDoc['memberIds'] as List<dynamic>);
      if (memberIds.contains(user?.uid)) {
        groupsUserIsMemberOf.add(groupDoc.id);
        for (final memberId in memberIds) {
          if (memberId != user?.uid) {
            final memberDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(memberId)
                .get();
            final phoneNumber = memberDoc['phone'] as String?;
            if (phoneNumber != null) {
              groupMembersPhoneNumbers.add(phoneNumber);
            }
          }
        }
      }
    }
    print('contacts  for groups are $groupMembersPhoneNumbers');
    // Send SMS to all recipients
    final recipients = [...contactsPhoneNumbers, ...groupMembersPhoneNumbers];

    Position position = await Geolocator.getCurrentPosition();

    final latitude = position.latitude.toString();
    final longitude = position.longitude.toString();
    final locationUrl =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    final message = 'Help! I am in an emergency! Track me here $locationUrl';
    String smsResult = await sendSMS(
        message: message, recipients: recipients, sendDirect: true);
    print(
        'sms status is $smsResult to $contactsPhoneNumbers and $groupMembersPhoneNumbers');

    // Send message to groups user is a member of

    print('group id are $groupsUserIsMemberOf');
    for (final groupId in groupsUserIsMemberOf) {
      final currentUser = await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .get();
      final username = currentUser['username'] as String?;
      final imageUrl = currentUser['imageUrl'] as String?;
      if (username != null && imageUrl != null) {
        FirebaseFirestore.instance
            .collection('groups')
            .doc(groupId)
            .collection('messages')
            .add({
          'text': message,
          'timestamp': Timestamp.now(),
          'username': username,
          'imageUrl': imageUrl,
          'userId': FirebaseAuth.instance.currentUser!.uid,
        });
      }
    }
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
