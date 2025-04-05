// ignore_for_file:
import 'dart:io';
import 'package:SwiftTalk/CONTROLLER/Push_Notifications.dart';
import 'package:SwiftTalk/CONTROLLER/User_Repository.dart';
import 'package:SwiftTalk/MODELS/Message.dart';
import 'package:SwiftTalk/MODELS/Notification.dart';
import 'package:SwiftTalk/MODELS/User.dart';
import 'package:aws_storage_service/aws_storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:SwiftTalk/API_KEYS.dart';
import 'package:path/path.dart' as path;

class ChatService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationRepository _notificationRepository =
      NotificationRepository();
  Future<void> SendMessage({required Message message}) async {
    final String currentUserId = _auth.currentUser!.uid;
    String ChatroomID = ([currentUserId, message.receiverId]..sort()).join("_");
    try {
      await _firestore
          .collection('chat_Rooms')
          .doc(ChatroomID)
          .collection('messages')
          .add(message.toMap());
      await _notificationRepository.updateNotifications(
          reciverId: message.receiverId,
          message: message.message,
          type: message.type);
      UserModel? user = await UserRepository().getUserById(message.receiverId);
      PushNotification.sendNotification(
        token: user?.fcmToken ?? '',
        title: "Message from ${message.senderName}",
        msg: message.message,
        type: message.type,
      );
    } catch (except) {
      print(except);
    }
  }

  Stream<List<dynamic>> getMessages(String userId, String otheruserId) {
    String chatroomID = ([userId, otheruserId]..sort()).join("_");

    return _firestore
        .collection('chat_Rooms')
        .doc(chatroomID)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        if (data['type'] == 'text' || data['type'] == 'deleted') {
          return Message.fromMap(data, doc.id);
        } else {
          return FileMessage.fromMap(data, doc.id);
        }
      }).toList();
    });
  }
}

class S3UploadService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationRepository _notificationRepository =
      NotificationRepository();

  final AwsCredentialsConfig _credentialsConfig = AwsCredentialsConfig(
      accessKey: ACCESS_KEY,
      secretKey: SECRET,
      bucketName: BUCKET,
      region: REGION);

  Future<String?> _uploadSmallFile(File file, String s3Path) async {
    try {
      final uploadConfig = UploadTaskConfig(
          credentailsConfig: _credentialsConfig,
          url: s3Path,
          uploadType: UploadType.file,
          file: file);
      final uploadFile = UploadFile(config: uploadConfig);
      uploadFile.uploadProgress.listen((progress) =>
          debugPrint('Upload Progress: ${progress[0]} / ${progress[1]}'));
      await uploadFile.upload();
      uploadFile.dispose();
      return _constructS3Url(s3Path);
    } catch (e) {
      debugPrint('Small File Upload Error: $e');
      return null;
    }
  }

  Future<String?> _uploadLargeFile(File file, String s3Path) async {
    try {
      final multipartConfig = MultipartUploadConfig(
          credentailsConfig: _credentialsConfig, file: file, url: s3Path);

      final multipartUpload = MultipartFileUpload(
          config: multipartConfig,
          onError: (error, list, s) =>
              debugPrint('Multipart Upload Error: $error'));

      multipartUpload.uploadProgress.listen((progress) => debugPrint(
          'Multipart Upload Progress: ${progress[0]} / ${progress[1]}'));
      final prepareSuccess = await multipartUpload.prepareMultipartRequest();
      if (prepareSuccess) {
        await multipartUpload.upload();
        return _constructS3Url(s3Path);
      }
      return null;
    } catch (e) {
      debugPrint('Large File Multipart Upload Error: $e');
      return null;
    }
  }

  String _constructS3Url(String objectKey) =>
      'https://${_credentialsConfig.bucketName}.s3.${_credentialsConfig.region}.amazonaws.com/$objectKey';

  Future<String?> uploadFileToS3(
      {required String reciverId,
      required File file,
      required String fileType,
      required bool sendNotification}) async {
    User user = FirebaseAuth.instance.currentUser!;
    String? result;
    int fileSize = 0;
    try {
      final fileName = path.basename(file.path);
      fileSize = await file.length();
      final maxBytes = 50 * 1024 * 1024;
      if (fileSize > maxBytes) {
        debugPrint('File size exceeds maximum limit of 50 MB');
        return null;
      }
      final s3Path =
          '$fileType/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      if (fileSize > 10 * 1024 * 1024) {
        result = await _uploadLargeFile(file, s3Path);
      } else {
        result = await _uploadSmallFile(file, s3Path);
      }
      if (result != null && sendNotification) {
        await sendFileMessage(
            message: FileMessage(
                senderName: user.displayName ?? '',
                senderId: user.uid,
                senderEmail: user.email ?? '',
                receiverId: reciverId,
                message: result,
                timestamp: Timestamp.now(),
                filename: path.basename(file.path),
                type: fileType,
                fileSize: fileSize));
        await _notificationRepository.addNotification(NotificationClass(
            message: path.basename(file.path),
            reciverId: reciverId,
            senderId: user.uid,
            senderName: user.displayName ?? '',
            timestamp: Timestamp.now(),
            type: fileType));
      } else {
        return result;
      }
    } catch (e) {
      debugPrint('S3 File Upload Error: $e');
      return null;
    }
    return null;
  }

  Future<void> sendFileMessage({required FileMessage message}) async {
    try {
      String chatroomId =
          ([_auth.currentUser!.uid, message.receiverId]..sort()).join("_");
      await _firestore
          .collection('chat_Rooms')
          .doc(chatroomId)
          .collection('messages')
          .add(message.toMap());
    } catch (e) {
      debugPrint('Firestore message send error: $e');
    }
  }
}
