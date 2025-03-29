// ignore_for_file:
import 'dart:io';
import 'package:aws_storage_service/aws_storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:SwiftTalk/API_KEYS.dart';
import 'package:SwiftTalk/pages/ChatInterface/Message.dart';
import 'package:path/path.dart' as path;

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
        type: 'text');

    List<String> ids = [currentUserId, reciverId];
    ids.sort();
    String ChatroomID = ids.join("_");
    try {
      await _firestore
          .collection('chat_Rooms')
          .doc(ChatroomID)
          .collection('messages')
          .add(newMessage.toMap());
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
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}

class S3UploadService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final AwsCredentialsConfig _credentialsConfig = AwsCredentialsConfig(
      accessKey: ACCESS_KEY,
      secretKey: SECRET,
      bucketName: BUCKET,
      region: REGION);

  Future<String?> uploadImageToS3(
      {required File imageFile, String? customPath}) async {
    try {
      if (!await imageFile.exists()) {
        debugPrint('File does not exist');
        return null;
      }
      final fileSize = await imageFile.length();
      final fileName = path.basename(imageFile.path);
      debugPrint('Uploading file: $fileName, Size: $fileSize bytes');
      final s3Path = customPath ??
          'chat_images/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      if (fileSize > 10 * 1024 * 1024) {
        return await _uploadLargeFile(imageFile, s3Path);
      } else {
        return await _uploadSmallFile(imageFile, s3Path);
      }
    } catch (e) {
      debugPrint('S3 Upload Error: $e');
      return null;
    }
  }

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

  Future<void> uploadAndSendVideo(
      {required File videoFile,
      required String receiverUid,
      required String receiverEmail}) async {
    try {
      final videoUrl = await uploadFileToS3(
          file: videoFile,
          fileType: 'videos',
          allowedExtensions: ['.mp4', '.mov', '.avi'],
          maxFileSizeMB: 50);

      if (videoUrl != null) {
        await sendFileMessage(
          fileName: videoFile.path.split('/').last,
          fileUrl: videoUrl,
          receiverUid: receiverUid,
          fileType: 'Video',
        );
      } else {
        debugPrint('Video upload failed');
      }
    } catch (e) {
      debugPrint('Video upload and send process error: $e');
    }
  }

  Future<void> uploadAndSendAudio({
    required File audioFile,
    required String receiverUid,
    required String receiverEmail,
  }) async {
    try {
      final audioUrl = await uploadFileToS3(
          file: audioFile,
          fileType: 'audio',
          allowedExtensions: ['.mp3', '.wav', '.m4a', '.aac'],
          maxFileSizeMB: 20);

      if (audioUrl != null) {
        await sendFileMessage(
          fileName: audioFile.path.split('/').last,
          fileUrl: audioUrl,
          receiverUid: receiverUid,
          fileType: 'Audio',
        );
      } else {
        debugPrint('Audio upload failed');
      }
    } catch (e) {
      debugPrint('Audio upload and send process error: $e');
    }
  }

  Future<void> uploadAndSendPDF({
    required File pdfFile,
    required String receiverUid,
    required String receiverEmail,
  }) async {
    try {
      final pdfUrl = await uploadFileToS3(
          file: pdfFile,
          fileType: 'documents',
          allowedExtensions: ['.pdf'],
          maxFileSizeMB: 30);

      if (pdfUrl != null) {
        await sendFileMessage(
          fileName: pdfFile.path.split('/').last,
          fileUrl: pdfUrl,
          receiverUid: receiverUid,
          fileType: 'PDF',
        );
      } else {
        debugPrint('PDF upload failed');
      }
    } catch (e) {
      debugPrint('PDF upload and send process error: $e');
    }
  }

  Future<String?> uploadFileToS3({
    required File file,
    required String fileType,
    List<String> allowedExtensions = const [],
    int maxFileSizeMB = 10,
  }) async {
    try {
      if (!await file.exists()) {
        debugPrint('File does not exist');
        return null;
      }
      final fileName = path.basename(file.path);
      final fileExtension = path.extension(fileName).toLowerCase();
      if (allowedExtensions.isNotEmpty &&
          !allowedExtensions.contains(fileExtension)) {
        debugPrint('Invalid file type. Allowed types: $allowedExtensions');
        return null;
      }

      final fileSize = await file.length();
      final maxBytes = maxFileSizeMB * 1024 * 1024;
      if (fileSize > maxBytes) {
        debugPrint('File size exceeds maximum limit of $maxFileSizeMB MB');
        return null;
      }
      final s3Path =
          '$fileType/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      if (fileSize > 10 * 1024 * 1024) {
        return await _uploadLargeFile(file, s3Path);
      } else {
        return await _uploadSmallFile(file, s3Path);
      }
    } catch (e) {
      debugPrint('S3 File Upload Error: $e');
      return null;
    }
  }

  Future<void> sendFileMessage(
      {required String fileName,
      required String fileUrl,
      required String receiverUid,
      required String fileType}) async {
    try {
      List<String> ids = [_auth.currentUser!.uid, receiverUid];
      ids.sort();
      String chatroomId = ids.join("_");
      await _firestore
          .collection('chat_Rooms')
          .doc(chatroomId)
          .collection('messages')
          .add({
        'fileName': fileName,
        'senderName': _auth.currentUser!.displayName,
        'senderId': _auth.currentUser!.uid,
        'senderEmail': _auth.currentUser!.email,
        'receiverId': receiverUid,
        'message': fileUrl,
        'type': fileType,
        'timestamp': Timestamp.now()
      });
    } catch (e) {
      debugPrint('Firestore message send error: $e');
    }
  }

  Future<void> sendImageMessage(
      {required String fileName,
      required String imageUrl,
      required String receiverUid}) async {
    try {
      List<String> ids = [_auth.currentUser!.uid, receiverUid];
      ids.sort();
      String chatroomId = ids.join("_");
      await _firestore
          .collection('chat_Rooms')
          .doc(chatroomId)
          .collection('messages')
          .add({
        'fileName': fileName,
        'senderName': _auth.currentUser!.displayName,
        'senderId': _auth.currentUser!.uid,
        'senderEmail': _auth.currentUser!.email,
        'receiverId': receiverUid,
        'message': imageUrl,
        'type': 'Image',
        'timestamp': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Firestore message send error: $e');
    }
  }

  Future<void> uploadAndSendImage({
    required File imageFile,
    required String receiverUid,
    required String receiverEmail,
  }) async {
    try {
      final imageUrl = await uploadImageToS3(imageFile: imageFile);

      if (imageUrl != null) {
        await sendImageMessage(
          fileName: imageFile.path.split("/").last,
          imageUrl: imageUrl,
          receiverUid: receiverUid,
        );
      } else {
        debugPrint('Image upload failed');
      }
    } catch (e) {
      debugPrint('Complete upload and send process error: $e');
    }
  }
}
