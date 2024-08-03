import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_mess/models/message.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;

import '../auth/auth_service.dart';
class ChatService extends ChangeNotifier {
  //get instance of firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;


  //get user stream
  Stream<List<Map<String, dynamic>>> getUserStream() {
    return _firestore.collection("Users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = doc.data();
        return user;
      }).toList();
    });
  }

  //get all users stream expect blocked users
  Stream<List<Map<String, dynamic>>> getUsersStreamExcludingBlocked() {
    final currentUser = _auth.currentUser;

    return _firestore
        .collection('Users')
        .doc(currentUser!.uid)
        .collection('BlockedUsers')
        .snapshots()
        .asyncMap((snapshot) async {
      //get block user ids
      final blockedUserIds = snapshot.docs.map((doc) => doc.id).toList();

      // get all users
      final usersSnapshot = await _firestore.collection('Users').get();

      //return as stream list, excluding current user and blocked users
      return usersSnapshot.docs
          .where((doc) =>
              doc.data()['email'] != currentUser.email &&
              !blockedUserIds.contains(doc.id))
          .map((doc) => doc.data())
          .toList();
    });
  }
  Future<String?> getTokenByUserId(String receiverId) async {
    DocumentSnapshot userDoc = await _firestore.collection('Users').doc(receiverId).get();
    if (userDoc.exists) {
      return userDoc['token'];
    }
    return null;
  }
  //send message
  Future<void> sendMessage(String receiverID, String message) async {
    final String currentUserID = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;

    final Timestamp timestamp = Timestamp.now();

    // Tạo một tin nhắn mới
    Message newMessage = Message(
      senderID: currentUserID,
      senderEmail: currentUserEmail,
      receiverID: receiverID,
      message: message,
      timestamp: timestamp,
    );

    List<String> ids = [currentUserID, receiverID];
    ids.sort();
    String chatRoomID = ids.join('_');

    await _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .add(newMessage.toMap());

    //
    String? token = await getTokenByUserId(receiverID);
    sendFCMMessage(message,currentUserEmail,token!);
  }

  //get message
  Stream<QuerySnapshot> getMessages(String userID, otherUserID) {
    //construct a chatroom ID for the two users

    List<String> ids = [userID, otherUserID];

    ids.sort();
    String chatRoomID = ids.join('_');

    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }

  //REPORT USER
  Future<void> reportUser(String messageId, String userId) async {
    final currentUser = _auth.currentUser;
    final report = {
      'reportedBy': currentUser!.uid,
      'messageId': messageId,
      'messageOwnerId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    };
    await _firestore.collection('Reports').add(report);
  }

  //BLOCK USER
  Future<void> blockUser(String userId) async {
    final currentUser = _auth.currentUser;
    await _firestore
        .collection('Users')
        .doc(currentUser!.uid)
        .collection('BlockedUsers')
        .doc(userId)
        .set({});
    notifyListeners();
  }

//UNBLOCK USER
  Future<void> unblockUser(String blockedUserId) async {
    final currentUser = _auth.currentUser;
    await _firestore
        .collection('Users')
        .doc(currentUser!.uid)
        .collection('BlockedUsers')
        .doc(blockedUserId)
        .delete();
  }

//GET BLOCK USERS STREAM
  Stream<List<Map<String, dynamic>>> getBlockedUserStream(String userId) {
    return _firestore
        .collection('Users')
        .doc(userId)
        .collection('BlockedUsers')
        .snapshots()
        .asyncMap((snapshot) async {
      final blockedUserIds = snapshot.docs.map((doc) => doc.id).toList();
      final userDocs = await Future.wait(blockedUserIds
          .map((id) => _firestore.collection('Users').doc(id).get()));
      //return as a list
      return userDocs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    });
  }


  Future<String> getToken() async {
    // Your client ID and client secret obtained from Google Cloud Console
    final serviceAccountJson = {
      "type": "service_account",
      "project_id": "appmess-1b730",
      "private_key_id": "469d4c94cd5aabb10a5a205e0eecd7cd7e959175",
      "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCP0CNQ/bomd9S+\nxsMmCzKaWHxRNyIOLfDY8irrLwyjW020KqZasAWvGrdHQPuyCWRe2leYdz/zJ6EP\nqdUniS1HO7sG+amqZb/r1ij5Gali+lu7r5rqCUxa89HMHc9Kj7rdr27C8MEbL4iW\nWXh6ZIuFBv60Pf8a6dJ7lqtD8mLWlxa/kdKtLCGSXs9NiylGqj6mn8FX+GpZsjF5\nhq3n1U59zJnJEpMI24D4Cgxh1+qbBI6X/1vvDzmSpeOlvt6aXOb5i/JGkALccE0r\nTa4hQfaUxxDHrNaVzbcmb5FvpmgGwjGmT/MENkorr2wyBMsERyJCcBLdusKRbDuT\naWSoCz5hAgMBAAECggEALLI7L7JT9x26LLrYrwu+4/KJXLJ+bpq/pqWJSkP6sRCw\n80RoJHpdoeDzQn2DXH+HxuUkYVn6sadI6vXVLi73uBJr28yfezqZbgJHBLiBiSYX\neZsn0gImzYPG2iIPqXRHVxvtmD+8PKdG07el9qAmLqeQZNN55FL0nH2k5/6+0kN2\nv0YT/bf73fUbx/hEWmMA2fGwWuQPuaR/9GBszGvTfrY7oDgyOza0kiILPORaQwIQ\nBTObyDC5MY5akS2L5r1qvwntoOX6NyMsHWpQuMLIKhegf4XkjVzum3OlxIfaXcf+\n/IqI38EIrGN0kPf5deQFbYpr0u/6Ownwu3u52DRwCwKBgQDDp8AnG6mVUtFdM6rT\nevCtAPyVLzUYM1wisowUX74eYLRuGvVqpk6QQRVMRDSbIs1URkOdMObDfwfPiXwk\n/1XiKcdTg/MV389KjqOWGQCyKzmxgTnfzDkXrw0LHYsRCBFpgJzJqw2UVDTTgMlQ\nxDWj92tZmb3xb6mRBKNWylhbywKBgQC8KxuDPSanGFuyZnFLmdLg9fL6bmY+c9SL\njuM1Kxn8R+5YTg/azRtBWxEc2+dne7sWz2WtPM3BoNK7gKl+/TbZHjYxUQfhsVIC\nGHbc/bj55UwcBqP63NeEzC/nEF9WGDTI3pZhgbS3m8oxX+BbemlEaIsoQ/IxygY8\nqqhAE+chAwKBgDfM6PV+YzAuLX3aVXb5EhkVNfRKQWdEhptytpa885jwVaUtVR70\njWWA2lUlAqfYFh1Z6MC1CKtq2ExtVpWqqNDWv31nHXX4ncMSyT7upI8r2slwJJRa\nR1Ik36By7Y2O8oBXaN/vQ/EwztwfV8sMGoxH7TrhqRVplj/AxeDj1q1fAoGBAIhN\nrZtOg55MvbeoD2+VGLWOU5jmubeJjjAdrCYKd8NQk61xtnhnVNPt1KKUBLboYOiw\nCVYJEn6tMZlTJPRxFfcGtHja2pu5J8+OyyNfw0t5tr0ibkw9Bv0SL6zwJi8mT64l\n1scA/th1yGwlqE57iJ9eH1dmiJ1aW1Q8xq3L/QPjAoGAJgaEmhnGfeVkrXtVq0AI\ncoZS/isqXCaIedQ32lR9Tht/GB5zLEuld86TjMHHqVbB28Y1bV4Tj5nhO0iUtX0P\ncVfUoasuxxB+qX95Ett3+xIXD+0OMLN1ypf2sLt/MJbVQXvToq5tDi06wLIkTlCA\ni5/F6BmGvdDR5V4sOHv35xU=\n-----END PRIVATE KEY-----\n",
      "client_email": "firebase-adminsdk-uchp5@appmess-1b730.iam.gserviceaccount.com",
      "client_id": "116430236470690584242",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-uchp5%40appmess-1b730.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com"
    };

    List<String> scopes = [
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/firebase.database",
      "https://www.googleapis.com/auth/firebase.messaging"
    ];

    http.Client client = await auth.clientViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
    );

    // Obtain the access token
    auth.AccessCredentials credentials = await auth.obtainAccessCredentialsViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
        scopes,
        client
    );

    // Close the HTTP client
    client.close();

    // Return the access token
    return credentials.accessToken.data;

  }
  //send notification
  Future<void> sendFCMMessage(String mess,String email,String token) async {
    try {
      final String serverKey = await getToken(); // Obtain the access token
      const String fcmEndpoint = 'https://fcm.googleapis.com/v1/projects/appmess-1b730/messages:send'; // Replace with your project ID
      if (token == null) {
        print('Failed to get FCM token');
        return;
      }

      print("FCM Key: $token");
      final Map<String, dynamic> message = {
        'message': {
          'token': token,
          // Token of the device you want to send the message to
          'notification': {
            'body': mess,
            'title': email,
          },
          'data': {
            'current_user_fcm_token': token,
            // Include the current user's FCM token in data payload
          },
        }
      };
      final http.Response response = await http.post(
        Uri.parse(fcmEndpoint),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $serverKey',
        },
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        print('FCM message sent successfully');
      } else {
        print('Failed to send FCM message: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('An error occurred: $e');
    }
  }

}
