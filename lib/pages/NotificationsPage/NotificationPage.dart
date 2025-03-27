import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projectx/pages/ChatInterface/chat_Service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPage();
}

class _NotificationPage extends State<NotificationPage> {
  final _auth = FirebaseAuth.instance;
  final _scrollController = ScrollController();
  @override
  Widget build(BuildContext context) {
    return _buildMessageList(context);
  }

  Widget _buildMessageList(BuildContext context) {
    ChatService chatService = ChatService();
    return StreamBuilder(
        stream: chatService.getNotifications(_auth.currentUser!.uid),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            return Column(
              children: [
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.teal.shade500,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 70,
                        child: IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.menu,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                      Flexible(
                          child: Text(
                        "Notifications",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w400,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                      ))
                    ],
                  ),
                ),
                Expanded(
                  child: Opacity(
                    opacity: snapshot.data!.docs.isEmpty ? 0.0 : 1.0,
                    child: ListView(
                      controller: _scrollController,
                      children: snapshot.data!.docs
                          .map(
                            (document) => _buildNotificationItem(document),
                          )
                          .toList(),
                    ),
                  ),
                )
              ],
            );
          }
          return Column(
            children: [
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.teal.shade500,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 70,
                      child: IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.menu,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    Flexible(
                        child: Text(
                      "Notifications",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w400,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                    ))
                  ],
                ),
              ),
              Expanded(
                child: Center(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.notifications,
                      size: 200,
                      color: Colors.teal.shade800,
                    ),
                    Text(
                      "Stay on Top of Your Incoming Notifications",
                      style: TextStyle(
                        fontSize: 23,
                        color: Colors.teal.shade800,
                        fontWeight: FontWeight.w400,
                      ),
                    )
                  ],
                )),
              ),
            ],
          );
        });
  }

  Widget _buildNotificationItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(
            Radius.circular(20),
          ),
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade500,
            ),
          ),
        ),
        child: Row(
          children: [
            data['type'] == 'Image'
                ? Image.asset(
                    'assets/imageup.png',
                    width: 50,
                  )
                : data['type'] == 'Video'
                    ? Image.asset(
                        'assets/videoup.png',
                        width: 50,
                      )
                    : data['type'] == 'Audio'
                        ? Image.asset(
                            'assets/audioup.png',
                            width: 50,
                          )
                        : data['type'] == 'PDFs'
                            ? Image.asset(
                                'assets/docup.png',
                                width: 50,
                              )
                            : Image.asset(
                                'assets/messageup.png',
                                width: 50,
                              ),
            const SizedBox(
              width: 10,
            ),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  data['type'] == 'Image'
                      ? Text(
                          'Image from ${data["senderName"]}',
                          style: const TextStyle(fontSize: 20),
                          softWrap: true,
                          overflow: TextOverflow
                              .ellipsis, // Fix overflow text problem
                        )
                      : data['type'] == 'Video'
                          ? Text(
                              "Video from ${data['senderName']}",
                              style: const TextStyle(fontSize: 20),
                              softWrap: true,
                              overflow: TextOverflow
                                  .ellipsis, // Fix overflow text problem
                            )
                          : Text(
                              "Message from ${data['senderName']}",
                              style: const TextStyle(fontSize: 20),
                              softWrap: true,
                              overflow: TextOverflow
                                  .ellipsis, // Fix overflow text problem
                            ),
                  Flexible(
                    child: Text(
                      data['message'],
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat('MMM dd, yyyy hh:mm a').format(
                          data['timestamp'].toDate(),
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          fontFamily: 'PT Sans Caption',
                        ),
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
