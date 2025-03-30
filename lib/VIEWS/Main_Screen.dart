import 'package:SwiftTalk/CONTROLLER/User_Repository.dart';
import 'package:SwiftTalk/MODELS/User.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:SwiftTalk/VIEWS/ChatScreen.dart';

class MessagesPage extends StatefulWidget {
  final AdvancedDrawerController dc;
  const MessagesPage({required this.dc, super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();
  final _userRepository = UserRepository();
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        IconButton(
                            icon:
                                Icon(Icons.menu, color: Colors.white, size: 28),
                            onPressed: () => widget.dc.showDrawer()),
                        SizedBox(width: 10),
                        Text("Chats",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold))
                      ]),
                      Row(children: [
                        IconButton(
                            icon: Icon(Icons.camera_alt,
                                color: Colors.white, size: 28),
                            onPressed: () {}),
                        IconButton(
                            icon: Icon(Icons.search,
                                color: Colors.white, size: 28),
                            onPressed: () {
                              setState(
                                  () => _isSearchVisible = !_isSearchVisible);
                            }),
                        IconButton(
                            icon: Icon(Icons.more_vert,
                                color: Colors.white, size: 28),
                            onPressed: () {})
                      ])
                    ]))));
  }

  Widget _buildSearchBar() => _isSearchVisible
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
                        setState(() => _isSearchVisible = false);
                      }),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none))))
      : SizedBox.shrink();

  Widget _buildChatList() => Expanded(
      child: StreamBuilder<List<UserModel>>(
          stream: _userRepository.getAllUsers(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                  child: Text('Something went wrong',
                      style: TextStyle(color: Colors.red)));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                  child: CircularProgressIndicator(color: Colors.teal));
            }
            if (!snapshot.hasData) {
              return const Center(
                child: Text("No Users Found"),
              );
            }

            final users = snapshot.data ?? [];
            return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  return _buildChatListItem(users[index]);
                });
          }));

  Widget _buildChatListItem(UserModel userData) => ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
          radius: 30,
          backgroundColor: Colors.grey.shade300,
          backgroundImage:
              userData.photoURL != '' ? NetworkImage(userData.photoURL) : null,
          child: userData.photoURL == ''
              ? Icon(Icons.account_circle, color: Colors.teal, size: 60)
              : null),
      title: Text(userData.username,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      subtitle: Text(userData.email,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey.shade600)),
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ChatPage(
                      receiver: userData,
                    )));
      });

  @override
  Widget build(BuildContext context) => Scaffold(
      body: Column(children: [
        _buildCustomAppBar(),
        _buildSearchBar(),
        _buildChatList()
      ]),
      floatingActionButton: FloatingActionButton(
          onPressed: () {},
          backgroundColor: Colors.teal,
          child: Icon(Icons.message, color: Colors.white)));
}

class MessageTile extends StatelessWidget {
  const MessageTile({super.key, required this.messageData, this.onTap});
  final MessageData messageData;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      child: Column(children: [
        Expanded(
            child: Icon(Icons.account_circle,
                size: 80, color: Colors.blue.shade700)),
        Padding(
            padding: const EdgeInsets.all(20),
            child: Text(messageData.sendname,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                textAlign: TextAlign.center))
      ]));
}

class MessageData {
  const MessageData(
      {required this.sendname,
      required this.sendmessage,
      required this.email,
      required this.uid});
  final String sendname;
  final String sendmessage;
  final String email;
  final String uid;
}
