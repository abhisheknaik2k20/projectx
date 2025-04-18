import 'package:SwiftTalk/CONTROLLER/Native_Implement.dart';
import 'package:SwiftTalk/CONTROLLER/NotificationService.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'dart:math';
import 'package:SwiftTalk/MODELS/Message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final String chatRoomID;
  const MessageBubble(
      {required this.chatRoomID, required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    final bool isCurrentUser =
        message.senderId == FirebaseAuth.instance.currentUser!.uid;
    final String formattedTime =
        CustomDateFormat.formatDateTime((message.timestamp).toDate());
    return GestureDetector(
        onLongPress: () {
          HapticFeedback.heavyImpact();
          _showBottomSheetDetails(message, isCurrentUser, context);
        },
        child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            alignment:
                isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Column(
                crossAxisAlignment: isCurrentUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.5),
                      decoration: BoxDecoration(
                          color: isCurrentUser
                              ? Colors.green.shade100
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.grey.shade300,
                                blurRadius: 2,
                                offset: const Offset(1, 1))
                          ]),
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isCurrentUser)
                              Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(message.senderName,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade800,
                                          fontSize: 12))),
                            _getMessageContent(message),
                            const SizedBox(height: 4),
                            Align(
                                alignment: Alignment.bottomRight,
                                child: Text(formattedTime,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600)))
                          ]))
                ])));
  }

  Widget _getMessageContent(Message message) {
    switch (message.type) {
      case "deleted":
        return Text(message.message,
            style: const TextStyle(fontSize: 16, color: Colors.grey));
      case _:
        return Text(message.message, style: const TextStyle(fontSize: 16));
    }
  }

  void _showBottomSheetDetails(
      Message message, bool isCurrentUser, BuildContext context) {
    final firebase = FirebaseFirestore.instance
        .collection('chat_Rooms')
        .doc(([message.senderId, message.receiverId]..sort()).join("_"))
        .collection("messages");
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
                color: const Color(0xFF1F2C34),
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              _whatsappInfoRow(Icons.person, "From", message.senderName),
              _whatsappInfoRow(Icons.access_time, "Sent",
                  CustomDateFormat.formatDateTime(message.timestamp.toDate())),
              const SizedBox(height: 24),
              message.type != 'deleted'
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                          _whatsappActionButton(
                            Icons.reply,
                            "Reply",
                            () => Navigator.pop(context),
                            Colors.blue[700]!,
                          ),
                          _whatsappActionButton(Icons.content_copy, "Copy", () {
                            Clipboard.setData(
                                ClipboardData(text: message.message));
                            Navigator.pop(context);
                          }, Colors.orange[700]!),
                          if (isCurrentUser)
                            _whatsappActionButton(Icons.delete, "Delete",
                                () async {
                              try {
                                await firebase.doc(message.id).update({
                                  "message": "This message was deleted",
                                  'type': 'deleted'
                                });
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Message deleted successfully')));
                              } catch (e) {
                                Navigator.pop(context);
                              }
                            }, Colors.red[700]!)
                        ])
                  : SizedBox.shrink(),
              const SizedBox(height: 16)
            ])));
  }

  Widget _whatsappActionButton(
      IconData icon, String label, VoidCallback onTap, Color color) {
    return InkWell(
        onTap: onTap,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25)),
              child: Icon(icon, color: color, size: 24)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12))
        ]));
  }

  Widget _whatsappInfoRow(IconData icon, String title, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(children: [
        Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(20)),
            child: Icon(icon, color: Colors.white, size: 20)),
        const SizedBox(width: 16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis)
        ]))
      ]));
}

// ignore: must_be_immutable
class FileMessageBubble extends StatelessWidget {
  final FileMessage message;
  final String chatRoomID;
  const FileMessageBubble(
      {required this.chatRoomID, required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    final bool isCurrentUser =
        message.senderId == FirebaseAuth.instance.currentUser!.uid;
    final String formattedTime =
        CustomDateFormat.formatDateTime((message.timestamp).toDate());
    return GestureDetector(
        onTap: () => _handleMediaTap(message, context),
        onLongPress: () {
          HapticFeedback.heavyImpact();
          _showBottomSheetDetails(message, isCurrentUser, context);
        },
        child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            alignment:
                isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Column(
                crossAxisAlignment: isCurrentUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.5),
                      decoration: BoxDecoration(
                          color: isCurrentUser
                              ? Colors.green.shade100
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.grey.shade300,
                                blurRadius: 2,
                                offset: const Offset(1, 1))
                          ]),
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isCurrentUser)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(message.senderName,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade800,
                                        fontSize: 12)),
                              ),
                            _getMessageContent(message),
                            const SizedBox(height: 4),
                            Text(
                              message.filename,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Align(
                                alignment: Alignment.bottomRight,
                                child: Text(formattedTime,
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600)))
                          ]))
                ])));
  }

  Widget _whatsappActionButton(
      IconData icon, String label, VoidCallback onTap, Color color) {
    return InkWell(
        onTap: onTap,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25)),
              child: Icon(icon, color: color, size: 24)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12))
        ]));
  }

  void _showBottomSheetDetails(
      FileMessage message, bool isCurrentUser, BuildContext context) {
    final firebase = FirebaseFirestore.instance
        .collection('chat_Rooms')
        .doc(([message.senderId, message.receiverId]..sort()).join("_"))
        .collection("messages");
    String formattedSize = _formatFileSize(message.fileSize);
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
                color: const Color(0xFF1F2C34),
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              _whatsappInfoRow(Icons.person, "From", message.senderName),
              _whatsappInfoRow(Icons.access_time, "Sent",
                  CustomDateFormat.formatDateTime(message.timestamp.toDate())),
              _whatsappInfoRow(
                  Icons.insert_drive_file, "File", message.filename),
              _whatsappInfoRow(Icons.data_usage, "Size", formattedSize),
              const SizedBox(height: 24),
              message.type != 'deleted'
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                          _whatsappActionButton(Icons.reply, "Reply",
                              () => Navigator.pop(context), Colors.blue[700]!),
                          _whatsappActionButton(Icons.download, "Download",
                              () async {
                            Navigator.of(context).pop();
                            await NotificationService().downloadFile(
                                message,
                                ([message.senderId, message.receiverId]..sort())
                                    .join("_"));
                          }, Colors.green[700]!),
                          if (isCurrentUser)
                            _whatsappActionButton(Icons.delete, "Delete",
                                () async {
                              try {
                                await firebase.doc(message.id).update({
                                  "message": "This file was deleted",
                                  'type': 'deleted'
                                });
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('File deleted successfully')));
                              } catch (e) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(
                                        'Error deleting file: ${e.toString()}')));
                              }
                            }, Colors.red[700]!)
                        ])
                  : SizedBox.shrink(),
              const SizedBox(height: 16)
            ])));
  }

  Widget _whatsappInfoRow(IconData icon, String title, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(children: [
        Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(20)),
            child: Icon(icon, color: Colors.white, size: 20)),
        const SizedBox(width: 16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis)
        ]))
      ]));
  String _formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    final suffixes = ["B", "KB", "MB", "GB", "TB"];
    int i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  Widget _getMessageContent(FileMessage message) {
    switch (message.type) {
      case 'Image':
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: 175,
              height: 175,
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(10)),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CustomCachedNetworkImage(imageUrl: message.message)))
        ]);
      case 'Video':
      case 'Audio':
      case 'PDF':
        final Map<String, List> mediaConfig = {
          'Video': [
            Icons.video_collection_sharp,
            Colors.blue,
            'Video',
            Colors.blue.shade100
          ],
          'Audio': [
            Icons.audiotrack,
            Colors.orange,
            'Audio',
            Colors.yellow.shade100
          ],
          'PDF': [
            Icons.picture_as_pdf,
            Colors.red,
            'PDF Document',
            Colors.red.shade100
          ]
        };
        final config = mediaConfig[message.type]!;
        return Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: config[3], borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.all(10),
            child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(config[0], color: config[1], size: 50),
                  const SizedBox(height: 10)
                ]));
      default:
        return Text(message.message, style: const TextStyle(fontSize: 16));
    }
  }

  void _handleMediaTap(FileMessage message, BuildContext context) async {
    try {
      final fileName = path.basename(Uri.parse(message.message).path);
      String? localFilePath;
      if (Platform.isAndroid) {
        final appDir = await getExternalStorageDirectory();
        final fileDir =
            Directory("${appDir?.path}/$chatRoomID/${message.type}");
        localFilePath = path.join(fileDir.path, fileName);
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        localFilePath = path.join(appDir.path, fileName);
      }
      final localFile = File(localFilePath);
      if (await localFile.exists()) {
        debugPrint('File exists locally, opening: $localFilePath');
        await OpenFile.open(localFilePath);
      } else {
        debugPrint('File not found locally, starting download');
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) =>
                Center(child: CircularProgressIndicator(color: Colors.teal)));
        final downloadedPath =
            await NotificationService().downloadFile(message, chatRoomID);
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        if (downloadedPath != null) {
          await OpenFile.open(downloadedPath);
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Failed to download file')));
        }
      }
    } catch (error) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      debugPrint('Error handling media tap: ${error.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening file: ${error.toString()}')));
    }
  }
}
