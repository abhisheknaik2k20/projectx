import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationInfo {
  final String senderName;
  final String senderID;
  final String senderEmail;
  final String reciverId;
  final String recieveMessage;
  final Timestamp timestamp;
  final String type;

  NotificationInfo({
    required this.senderName,
    required this.senderID,
    required this.senderEmail,
    required this.reciverId,
    required this.recieveMessage,
    required this.timestamp,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderName': senderName,
      'senderId': senderID,
      'senderEmail': senderEmail,
      'reciverId': reciverId,
      'message': recieveMessage,
      'timestamp': timestamp,
      'type': type,
    };
  }
}
