import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:SwiftTalk/pages/API_Call_Screen/Screen1.dart';
import 'dart:convert';

import 'package:SwiftTalk/pages/Profile.dart';

class WhatsAppChatAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String receiverEmail;
  final String receiverUid;
  final String receiverName;
  final String chatroomID;

  const WhatsAppChatAppBar({
    super.key,
    required this.receiverEmail,
    required this.receiverUid,
    required this.receiverName,
    required this.chatroomID,
  });
  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + 10);

  @override
  Widget build(BuildContext context) {
    FirebaseFirestore db = FirebaseFirestore.instance;
    FirebaseAuth auth = FirebaseAuth.instance;
    List<String> ids = [auth.currentUser!.uid, receiverUid];
    ids.sort();
    String ChatroomID = ids.join("_");

    void setReciver() async {
      await db
          .collection('users')
          .doc(receiverUid)
          .collection('call_info')
          .doc(receiverUid)
          .set(
        {
          'key': ChatroomID,
          'reciving_Call': true,
          'sending_Call': false,
          'caller_Name': auth.currentUser?.displayName
        },
      );
    }

    void setSender() async {
      await db
          .collection('users')
          .doc(auth.currentUser!.uid)
          .collection('call_info')
          .doc(auth.currentUser!.uid)
          .set(
        {
          'key': ChatroomID,
          'reciving_Call': false,
          'sending_Call': true,
        },
      );
    }

    return AppBar(
        backgroundColor: Colors.teal, // WhatsApp green
        leadingWidth: 30,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(receiverUid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfilePage(UserUID: receiverUid),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(
                        snapshot.data!['photoURL'] ??
                            'https://default-avatar-url.com/avatar.jpg',
                      ),
                      radius: 20,
                    ),
                    SizedBox(width: 10),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            receiverName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Text(
                            snapshot.data!['status'] ?? 'Offline',
                            style: TextStyle(
                              fontSize: 12,
                              color: snapshot.data!['status'] == 'Online'
                                  ? Colors.blue
                                  : Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
            return Text(
              receiverName,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.video_call, color: Colors.white),
            onPressed: () async {
              await db
                  .collection('users')
                  .doc(receiverUid)
                  .update({'isCall': true});

              // Fetch receiver's FCM token
              DocumentSnapshot dataSnapshot =
                  await db.collection('users').doc(receiverUid).get();

              Map<String, dynamic>? userData =
                  dataSnapshot.data() as Map<String, dynamic>?;

              // Prepare push notification payload
              var notificationPayload = {
                'to': userData?['fcmToken'],
                'priority': 'high',
                'notification': {
                  'title': 'Incoming Call',
                  'body': '${auth.currentUser?.displayName} is calling you',
                },
                'data': {
                  'type': 'voice_call',
                  'chatroomId': chatroomID,
                }
              };

              await http.post(
                Uri.parse('https://fcm.googleapis.com/fcm/send'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'key=YOUR_FCM_SERVER_KEY',
                },
                body: jsonEncode(notificationPayload),
              );
              setReciver();
              setSender();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => MyHomePage()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.call, color: Colors.white),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.white),
              onSelected: (String choice) {
                switch (choice) {
                  case 'View Contact':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(UserUID: receiverUid),
                      ),
                    );
                    break;
                  case 'Media':
                    break;
                  case 'Search':
                    break;
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'View Contact',
                      child: Text('View Contact'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'Media',
                      child: Text('Media'),
                    ),
                    const PopupMenuItem<String>(
                        value: 'Search', child: Text('Search'))
                  ])
        ]);
  }
}
