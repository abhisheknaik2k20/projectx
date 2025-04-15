import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  String? id;
  final String senderName;
  final String senderId;
  final String senderEmail;
  final String receiverId;
  final String message;
  final Timestamp timestamp;
  final String type;

  Message(
      {this.id,
      required this.senderName,
      required this.senderId,
      required this.senderEmail,
      required this.receiverId,
      required this.message,
      required this.timestamp,
      required this.type});

  factory Message.fromMap(Map<String, dynamic> map, String docId) {
    return Message(
        id: docId,
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

  Message copyWith(
      {String? id,
      String? senderName,
      String? senderId,
      String? senderEmail,
      String? receiverId,
      String? message,
      Timestamp? timestamp,
      String? type}) {
    return Message(
      id: id ?? this.id,
      senderName: senderName ?? this.senderName,
      senderId: senderId ?? this.senderId,
      senderEmail: senderEmail ?? this.senderEmail,
      receiverId: receiverId ?? this.receiverId,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
    );
  }
}

class FileMessage extends Message {
  final String filename;
  int fileSize;

  FileMessage(
      {super.id,
      required super.senderName,
      required super.senderId,
      required super.senderEmail,
      required super.receiverId,
      required super.message,
      required super.timestamp,
      required this.filename,
      required super.type,
      this.fileSize = 0});

  factory FileMessage.fromMap(Map<String, dynamic> map, String docId) {
    return FileMessage(
        id: docId,
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

// Extended Message model to handle encryption
class EncryptedMessage extends Message {
  final bool isEncrypted;

  EncryptedMessage({
    required String senderName,
    required String senderId,
    required String senderEmail,
    required String receiverId,
    required String message,
    required Timestamp timestamp,
    required String type,
    this.isEncrypted = true,
    String? id,
  }) : super(
          senderName: senderName,
          senderId: senderId,
          senderEmail: senderEmail,
          receiverId: receiverId,
          message: message,
          timestamp: timestamp,
          type: type,
          id: id,
        );

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map['isEncrypted'] = isEncrypted;
    return map;
  }

  factory EncryptedMessage.fromMap(Map<String, dynamic> map, String id) {
    return EncryptedMessage(
      senderName: map['senderName'] ?? '',
      senderId: map['senderId'] ?? '',
      senderEmail: map['senderEmail'] ?? '',
      receiverId: map['receiverId'] ?? '',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] ?? Timestamp.now(),
      type: map['type'] ?? 'text',
      isEncrypted: map['isEncrypted'] ?? false,
      id: id,
    );
  }
}
