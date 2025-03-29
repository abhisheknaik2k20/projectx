import 'package:SwiftTalk/pages/ChatInterface/ChatScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatelessWidget {
  final AdvancedDrawerController dc;

  const NotificationPage({required this.dc, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildNotificationList(context));
  }

  Widget _buildNotificationList(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    Stream<QuerySnapshot> getNotifications(String userId) {
      return firestore
          .collection('users')
          .doc(userId)
          .collection('noti_Info')
          .orderBy('timestamp', descending: false)
          .snapshots();
    }

    return StreamBuilder<QuerySnapshot>(
        stream: getNotifications(currentUser!.uid),
        builder: (context, snapshot) {
          return CustomScrollView(slivers: [
            SliverAppBar(
                backgroundColor: Colors.teal,
                leading: IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () => dc.showDrawer()),
                title: const Text('Notifications',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w500)),
                floating: true),
            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty)
              SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                final document = snapshot.data!.docs[index];
                return _buildNotificationItem(document, context);
              }, childCount: snapshot.data!.docs.length))
            else
              SliverFillRemaining(child: _buildEmptyState())
          ]);
        });
  }

  Widget _buildEmptyState() {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.notifications_none_outlined,
          size: 120, color: Colors.teal.shade300),
      const SizedBox(height: 16),
      Text('No Notifications',
          style: TextStyle(
              fontSize: 22,
              color: Colors.teal.shade800,
              fontWeight: FontWeight.w400)),
      const SizedBox(height: 8),
      Text('You\'re all caught up!',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600))
    ]));
  }

  Widget _buildNotificationItem(
      DocumentSnapshot document, BuildContext context) {
    final data = document.data() as Map<String, dynamic>;

    final typeIcons = {
      'Image': Icons.image,
      'Video': Icons.video_collection,
      'Audio': Icons.audio_file,
      'PDF': Icons.file_copy,
      'text': Icons.chat
    };

    return Dismissible(
        key: Key(document.id),
        background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white)),
        direction: DismissDirection.endToStart,
        onDismissed: (direction) => FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .collection('noti_Info')
            .doc(document.id)
            .delete(),
        child: ListTile(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => ChatPage(
                    receiverUid: data['senderId'],
                    receiverName: data['senderName']))),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading:
                Icon(typeIcons[data['type']], size: 50, color: Colors.teal),
            title: Text(_getNotificationTitle(data),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            subtitle:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(data['message'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
              const SizedBox(height: 4),
              Text(
                  DateFormat('MMM dd, yyyy hh:mm a')
                      .format(data['timestamp'].toDate()),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500))
            ])));
  }

  String _getNotificationTitle(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'Image':
        return 'Image from ${data["senderName"]}';
      case 'Video':
        return 'Video from ${data["senderName"]}';
      case 'Audio':
        return 'Audio from ${data["senderName"]}';
      case 'PDF':
        return 'PDF from ${data["senderName"]}';
      default:
        return 'Message from ${data["senderName"]}';
    }
  }
}
