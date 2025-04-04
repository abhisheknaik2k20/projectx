import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String? description;
  final String email;
  final String name;
  final String uid;
  final String photoURL;
  final String status;
  final Timestamp? createdAt;
  final String username;
  final bool isCall;
  final String? fcmToken;

  UserModel({
    required this.email,
    required this.name,
    required this.uid,
    required this.photoURL,
    this.status = 'Online',
    this.createdAt,
    required this.username,
    this.isCall = false,
    this.fcmToken,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'uid': uid,
      'photoURL': photoURL,
      'status': status,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'username': username,
      'isCall': isCall,
      'fcmToken': fcmToken,
      'description': description
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
        email: map['email'] ?? '',
        name: map['name'] ?? '',
        uid: map['uid'] ?? '',
        photoURL: map['photoURL'] ?? '',
        status: map['status'] ?? 'Offline',
        createdAt: map['createdAt'],
        username: map['username'] ?? '',
        isCall: map['isCall'] ?? false,
        fcmToken: map['fcmToken'],
        description: map['description']);
  }

  UserModel copyWith(
      {String? email,
      String? name,
      String? uid,
      String? photoURL,
      String? status,
      Timestamp? createdAt,
      String? username,
      bool? isCall,
      String? fcmToken}) {
    return UserModel(
        description: description ?? this.description,
        email: email ?? this.email,
        name: name ?? this.name,
        uid: uid ?? this.uid,
        photoURL: photoURL ?? this.photoURL,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        username: username ?? this.username,
        isCall: isCall ?? this.isCall,
        fcmToken: fcmToken ?? this.fcmToken);
  }
}
