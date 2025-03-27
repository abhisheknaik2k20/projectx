// ignore_for_file: non_constant_identifier_names
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projectx/pages/ChatInterface/Message.dart';

class ChatService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> SendMessage(String reciverId, String message) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email.toString();
    final Timestamp timestamp = Timestamp.now();

    Message newMessage = Message(
      senderName: _auth.currentUser!.displayName ?? '',
      senderID: currentUserId,
      senderEmail: currentUserEmail,
      reciverId: reciverId,
      recieveMessage: message,
      timestamp: timestamp,
      type: 'text',
    );

    List<String> ids = [currentUserId, reciverId];
    ids.sort();
    String ChatroomID = ids.join("_");
    try {
      await _firestore
          .collection('chat_Rooms')
          .doc(ChatroomID)
          .collection('messages')
          .add(newMessage.toMap());
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(reciverId)
          .get();
      Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
      print("fcmToken : ${data!['fcmToken']}");
      var object = {
        'to': data['fcmToken'],
        'priority': 'high',
        'notification': {
          'title': _auth.currentUser!.displayName,
          'body': message,
          'persistent': true,
        },
      };
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'key=AAAADHtCBX4:APA91bFlK9ZKNKNP0c46KUBQRgnEpf4d1mXhjtjbZXO0Wcp3-zFTPYkKzqUNooJjw6NIwT7BCwlp0Zh9jQ8OpunTJcUk2GsHUj5pngLO-8CXiPPdhGzw0NCStfyryRIel6RkDhn5OTfH',
        },
        body: jsonEncode(object),
      );
      NotificationInfo notificationInfo = NotificationInfo(
        senderName: _auth.currentUser!.displayName!,
        senderID: currentUserId,
        senderEmail: currentUserEmail,
        reciverId: reciverId,
        recieveMessage: message,
        timestamp: timestamp,
        type: 'text',
      );
      await _firestore
          .collection('users')
          .doc(reciverId)
          .collection('noti_Info')
          .add(notificationInfo.toMap());
    } catch (except) {
      print(except);
    }
  }

  Stream<QuerySnapshot> getMessages(String userId, String otheruserId) {
    List<String> ids = [userId, otheruserId];
    ids.sort();
    String ChatroomID = ids.join("_");
    return _firestore
        .collection('chat_Rooms')
        .doc(ChatroomID)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Stream<QuerySnapshot> getNotifications(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('noti_Info')
        .orderBy(
          'timestamp',
          descending: true,
        )
        .snapshots();
  }
}
