/*import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> sendEmergencyNotification(String currentUserUid) async {
    // Step 1: Get the current user's phone number from their `users` document
    final DocumentSnapshot currentUserDoc =
        await _firestore.collection('users').doc(currentUserUid).get();
    final String emergencyContactPhoneNumber =
        currentUserDoc.get('emergencyContact.phoneNumber');

    // Step 2: Query the `users` collection to find any user whose phone number matches the phone number of the current user's emergency contact
    final QuerySnapshot usersQuerySnapshot = await _firestore
        .collection('users')
        .where('phoneNumber', isEqualTo: emergencyContactPhoneNumber)
        .get();

    // Step 3: Get the `id` of each user who matches the phone number and check if they have a token in the `user_tokens` collection
    final List<String> userTokens = [];
    for (final DocumentSnapshot userDoc in usersQuerySnapshot.docs) {
      final String userId = userDoc.id;
      final DocumentSnapshot userTokenDoc =
          await _firestore.collection('user_tokens').doc(userId).get();
      final String userToken = userTokenDoc.get('token');
      if (userToken != null) {
        userTokens.add(userToken);
      }
    }

    // Step 4: If a user has a token, add it to a list of tokens to send the notification to

    // Step 5: Query the `groups` collection to find all the groups that the current user is a member of
    final QuerySnapshot groupsQuerySnapshot = await _firestore
        .collection('groups')
        .where('members', arrayContains: currentUserUid)
        .get();

    // Step 6: For each group, get the `id` of all the users who are members of the group and check if they have a token in the `user_tokens` collection
    for (final DocumentSnapshot groupDoc in groupsQuerySnapshot.docs) {
      final List<dynamic> members = groupDoc.get('members');
      for (final String memberId in members) {
        final DocumentSnapshot userTokenDoc =
            await _firestore.collection('user_tokens').doc(memberId).get();
        final String userToken = userTokenDoc.get('token');
        if (userToken != null) {
          userTokens.add(userToken);
        }
      }
    }

    // Step 7: If a user has a token, add it to the list of tokens to send
    final List<String> tokensToSend = [];
    for (final String userToken in userTokens) {
      if (userToken != null) {
        tokensToSend.add(userToken);
      }
    }

    // Step 8: Create the notification message to send
    final String notificationTitle = 'Emergency Alert';
    final String notificationBody =
        'Emergency Alert from ${currentUserDoc.get('name')}';
    final Map<String, dynamic> notificationData = {'type': 'emergency'};

    // Step 9: Send the notification to all the tokens in the list
    if (tokensToSend.isNotEmpty) {
      final sendResponse = await _firebaseMessaging.send(
        FirebaseMessage(
          notification: FirebaseNotification(
            title: notificationTitle,
            body: notificationBody,
          ),
          data: notificationData,
          tokens: tokensToSend,
        ),
      );
    }
  }
}
*/