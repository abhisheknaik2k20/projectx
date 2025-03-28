import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:projectx/pages/ChatInterface/ChatScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessagesPage extends StatefulWidget {
  final AdvancedDrawerController dc;
  const MessagesPage({required this.dc, super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildCustomAppBar() {
    return Container(
      decoration: BoxDecoration(color: Colors.teal),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.menu, color: Colors.white, size: 28),
                    onPressed: () => widget.dc.showDrawer(),
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Chats",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.camera_alt, color: Colors.white, size: 28),
                    onPressed: () {
                      // Camera functionality
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.search, color: Colors.white, size: 28),
                    onPressed: () {
                      setState(() {
                        _isSearchVisible = !_isSearchVisible;
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.more_vert, color: Colors.white, size: 28),
                    onPressed: () {
                      // More options
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return _isSearchVisible
        ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users',
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _isSearchVisible = false;
                    });
                  },
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          )
        : SizedBox.shrink();
  }

  Widget _buildChatList() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Something went wrong',
                style: TextStyle(color: Colors.red),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: Colors.teal,
              ),
            );
          }
          final currentUser = FirebaseAuth.instance.currentUser;
          final users = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['uid'] != currentUser?.uid;
          }).toList();

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>;
              return _buildChatListItem(userData);
            },
          );
        },
      ),
    );
  }

  Widget _buildChatListItem(Map<String, dynamic> userData) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 30,
        backgroundColor: Colors.grey.shade300,
        backgroundImage:
            userData['photoURL'] != '' && userData['photoURL'].isNotEmpty
                ? NetworkImage(userData['photoURL'])
                : null,
        child: userData['photoURL'] == '' || userData['photoURL'].isEmpty
            ? Icon(
                Icons.account_circle,
                color: Colors.teal,
                size: 60,
              )
            : null,
      ),
      title: Text(
        userData['username'] ?? 'Unknown User',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      subtitle: Text(
        userData['email'] ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.grey.shade600,
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              receiverName: userData['username'] ?? 'Unknown',
              receiverEmail: userData['email'] ?? '',
              receiverUid: userData['uid'] ?? '',
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildCustomAppBar(),
          _buildSearchBar(),
          _buildChatList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Open new chat screen or user selection
        },
        backgroundColor: Colors.teal, // WhatsApp green
        child: Icon(Icons.message, color: Colors.white),
      ),
    );
  }
}

class MessageTile extends StatelessWidget {
  const MessageTile({super.key, required this.messageData, this.onTap});
  final MessageData messageData;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: onTap,
        child: Column(children: [
          Expanded(
            child: Icon(Icons.account_circle,
                size: 80, color: Colors.blue.shade700),
          ),
          Padding(
              padding: const EdgeInsets.all(20),
              child: Text(messageData.sendname,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                  textAlign: TextAlign.center))
        ]));
  }
}

class MessageTileTwo extends StatelessWidget {
  const MessageTileTwo({super.key, required this.messageData, this.onTap});
  final MessageData messageData;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => ChatPage(
                  receiverName: messageData.sendname,
                  receiverEmail: messageData.email,
                  receiverUid: messageData.uid)));
        },
        child: Padding(
            padding: const EdgeInsets.only(left: 5, right: 5),
            child: Container(
                decoration: BoxDecoration(
                    border:
                        Border(bottom: BorderSide(color: Colors.grey.shade400)),
                    borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20))),
                child: Row(children: [
                  Padding(
                      padding: const EdgeInsets.all(10),
                      child: CircleAvatar(
                          backgroundColor: Colors.teal.shade500,
                          child: const Icon(Icons.account_circle, size: 40))),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(messageData.sendname,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20)),
                        Text(messageData.sendmessage,
                            style: const TextStyle(fontSize: 10))
                      ]))
                ]))));
  }
}

class MessageData {
  const MessageData({
    required this.sendname,
    required this.sendmessage,
    required this.email,
    required this.uid,
  });
  final String sendname;
  final String sendmessage;
  final String email;
  final String uid;
}
