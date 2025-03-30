import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderName;
  final String senderId;
  final String senderEmail;
  final String receiverId;
  final String message;
  final Timestamp timestamp;
  final String type;

  Message(
      {required this.senderName,
      required this.senderId,
      required this.senderEmail,
      required this.receiverId,
      required this.message,
      required this.timestamp,
      required this.type});

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
        senderName: map['senderName'] ?? '',
        senderId: map['senderId'] ?? '',
        senderEmail: map['senderEmail'] ?? '',
        receiverId: map['reciverId'] ?? '',
        message: map['message'] ?? '',
        timestamp: map['timestamp'],
        type: map['type'] ?? 'text');
  }

  Map<String, dynamic> toMap() {
    return {
      'senderName': senderName,
      'senderId': senderId,
      'senderEmail': senderEmail,
      'reciverId': receiverId,
      'message': message,
      'timestamp': timestamp,
      'type': type
    };
  }
}

class FileMessage extends Message {
  final String filename;
  int fileSize;

  FileMessage(
      {required super.senderName,
      required super.senderId,
      required super.senderEmail,
      required super.receiverId,
      required super.message,
      required super.timestamp,
      required this.filename,
      required super.type,
      this.fileSize = 0});

  factory FileMessage.fromMap(Map<String, dynamic> map) {
    return FileMessage(
        senderName: map['senderName'] ?? '',
        senderId: map['senderId'] ?? '',
        senderEmail: map['senderEmail'] ?? '',
        receiverId: map['reciverId'] ?? '',
        message: map['message'] ?? '',
        timestamp: map['timestamp'],
        filename: map['filename'] ?? '',
        type: map['type'],
        fileSize: map['fileSize'] ?? 0);
  }

  @override
  Map<String, dynamic> toMap() {
    final baseMap = super.toMap();
    return {...baseMap, 'filename': filename, 'fileSize': fileSize};
  }
}
