import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FCMServices {
  FirebaseMessaging _fcm = FirebaseMessaging.instance;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FCMServices() {
    initializeFirebase();
  }

  Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
  }

  Future<void> sendEmergencyNotifications(
      String userId, String location) async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    print(fcmToken);
    try {
      // Retrieve user's emergency contacts
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(userId).get();
      if (!userSnapshot.exists) {
        // Handle case where user ID is invalid
        return;
      }
      List<String> emergencyContacts = [];
      Map<String, dynamic>? userData =
          userSnapshot.data() as Map<String, dynamic>?;

      if (userData != null && userData.containsKey('emergency_contacts')) {
        emergencyContacts =
            List<String>.from(userData['emergency_contacts'] ?? []);
      }

      // Retrieve groups user is a member of
      QuerySnapshot groupsSnapshot = await _firestore
          .collection('groups')
          .where('members', arrayContains: userId)
          .get();
      List<String> groupIds = groupsSnapshot.docs.map((doc) => doc.id).toList();

      // Add additional data to FCM message payload
      String? userName = userData?['username']?.toString();
      String? profilePicture = userData?['imageUrl']?.toString();

      Map<String, dynamic> message = {
        'notification': {
          'title': 'Emergency Alert from ${userName ?? ''}',
          'body': '${userName ?? ''} is in danger at $location',
          'click_action': 'FLUTTER_NOTIFICATION_CLICK'
        },
        'data': {
          'location': location,
          'userName': userName,
          'profilePicture': profilePicture,
        }
      };

      // Send FCM message to each contact with a valid fcmToken
      List<String> contactTokens = [];
      List<String> contactEmails = [];

      for (String contact in emergencyContacts) {
        DocumentSnapshot contactSnapshot = await _firestore
            .collection('users')
            .where('email', isEqualTo: contact)
            .limit(1)
            .get()
            .then((querySnapshot) => querySnapshot.docs.first);

        if (contactSnapshot.exists) {
          Map<String, dynamic>? contactData =
              contactSnapshot.data() as Map<String, dynamic>?;

          if (contactData != null &&
              contactData.containsKey('fcm_token') &&
              contactData['fcm_token'] != null) {
            String contactToken = contactData['fcm_token'] ?? '';
            contactTokens.add(contactToken);
            contactEmails.add(contact);
          }
        }
      }

      List<Future<void>> contactTokenMessageFutures =
          contactTokens.map((contactToken) async {
        await _fcm.sendMessage(
          to: contactToken,
          data: message.map((key, value) => MapEntry(key, value.toString())),
        );
      }).toList();
      await Future.wait(contactTokenMessageFutures);
      List<String> groupTokens = [];

      List<String> allTokens = [...contactTokens, ...groupTokens];
      List<Future<void>> allTokenMessageFutures = allTokens.map((token) async {
        await _fcm.sendMessage(
          to: token,
          data: message.map((key, value) => MapEntry(key, value.toString())),
        );
      }).toList();
      await Future.wait(allTokenMessageFutures);

      // Send FCM message to each group
      // List<String> groupTokens = [];
      List<Future<void>> groupMessageFutures = groupIds.map((groupId) async {
        await _fcm.subscribeToTopic(groupId);
        String groupToken = '/topics/$groupId';
        groupTokens.add(groupToken);
        await _fcm.sendMessage(
          to: groupToken,
          data: message.map((key, value) => MapEntry(key, value.toString())),
        );
      }).toList();
      await Future.wait(groupMessageFutures);
    } catch (e) {
      // Handle any errors that occur
      print('Error sending emergency notifications: $e');
    }
  }
}
