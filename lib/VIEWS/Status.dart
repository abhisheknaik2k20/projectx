import 'dart:io';

import 'package:SwiftTalk/CONTROLLER/Chat_Service.dart';
import 'package:SwiftTalk/CONTROLLER/User_Repository.dart';
import 'package:SwiftTalk/MODELS/User.dart';
import 'package:SwiftTalk/VIEWS/Status_Preview.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class Community {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final int memberCount;
  final DateTime lastActivity;

  Community(
      {required this.id,
      required this.name,
      required this.description,
      required this.imageUrl,
      required this.memberCount,
      required this.lastActivity});

  factory Community.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Community(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? 'assets/default_community.jpg',
      memberCount: data['memberCount'] ?? 0,
      lastActivity: (data['lastActivity'] as Timestamp).toDate(),
    );
  }
}

class WhatsAppStatusCommunityScreen extends StatefulWidget {
  const WhatsAppStatusCommunityScreen({super.key});

  @override
  State<WhatsAppStatusCommunityScreen> createState() =>
      _WhatsAppStatusCommunityScreenState();
}

class _WhatsAppStatusCommunityScreenState
    extends State<WhatsAppStatusCommunityScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> _communitiesStream;
  UserModel? _currentUser;
  final ImagePicker imagePicker = ImagePicker();
  List<XFile> selectedImages = [];
  final S3UploadService _s3 = S3UploadService();
  final UserRepository _userRepository = UserRepository();
  bool isLoading = false;

  getUserData() async => _currentUser =
      await _userRepository.getCurrentUser() ?? _userRepository.errorUser();

  @override
  void initState() {
    super.initState();
    getUserData();
    _communitiesStream = _firestore
        .collection('communities')
        .orderBy('lastActivity', descending: true)
        .limit(20)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
            backgroundColor: Colors.teal,
            title: Text('Status',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            actions: [
              IconButton(icon: Icon(Icons.search), onPressed: () {}),
              IconButton(icon: Icon(Icons.more_vert), onPressed: () {})
            ]),
        body: Column(children: [
          Container(
              height: 125,
              color: Colors.grey[100],
              child: StreamBuilder(
                  stream: _userRepository.getAllUsers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    List<UserModel> users = snapshot.data!;
                    return ListView(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildMyStatusCircle(),
                          ...users.map((user) => _buildStatusCircle(user))
                        ]);
                  })),
          Divider(height: 1),
          Expanded(
              child: StreamBuilder<QuerySnapshot>(
                  stream: _communitiesStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text('No communities available'));
                    }

                    List<Community> communities = snapshot.data!.docs
                        .map((doc) => Community.fromFirestore(doc))
                        .toList();

                    return ListView(children: [
                      _buildCommunityHeader(),
                      ...communities
                          .map((community) => _buildCommunityItem(community))
                    ]);
                  }))
        ]),
        floatingActionButton: FloatingActionButton(
            backgroundColor: Color(0xFF25D366),
            child: Icon(Icons.group_add),
            onPressed: () {}));
  }

  Widget _buildMyStatusCircle() {
    return GestureDetector(
      onTap: () async {
        UserModel? user = await _userRepository.getCurrentUser();
        if (user == null) return;
        if (user.statusImages == null || user.statusImages!.isEmpty) {
          try {
            setState(() => isLoading = true);
            final pickedImages = await imagePicker.pickMultiImage();
            if (pickedImages.isEmpty) {
              setState(() => isLoading = false);
              return;
            }

            final files =
                pickedImages.map((image) => File(image.path)).toList();
            final urls = await Future.wait(files.map((file) =>
                _s3.uploadFileToS3(
                    reciverId: null,
                    file: file,
                    fileType: "Image",
                    sendNotification: false)));

            final validUrls = urls.whereType<String>().toList();
            _userRepository.updateStatusImages(
                _currentUser?.uid ?? '', validUrls);
            setState(() => isLoading = false);
            if (validUrls.isNotEmpty) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => StatusPreviewScreen(user: user)));
            }
          } catch (e) {
            setState(() => isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error uploading images: $e')));
          }
        } else {
          if (user.statusImages!.isNotEmpty) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => StatusPreviewScreen(user: user)));
          }
        }
      },
      child: Container(
          margin: EdgeInsets.symmetric(horizontal: 8),
          child: Column(children: [
            Stack(children: [
              CircleAvatar(
                  radius: 30,
                  backgroundImage:
                      CachedNetworkImageProvider(_currentUser?.photoURL ?? '')),
              Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                      height: 20,
                      width: 20,
                      decoration: BoxDecoration(
                        color: Color(0xFF25D366),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(Icons.add, color: Colors.white, size: 16)))
            ]),
            SizedBox(height: 4),
            Text('My Status', style: TextStyle(fontSize: 12))
          ])),
    );
  }

  Widget _buildStatusCircle(UserModel user) {
    // if (user.statusImages == null || user.statusImages!.isEmpty) {
    //   return Container();
    // } ENABLE THIS IS PRODUCTION BUILD
    return GestureDetector(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => StatusPreviewScreen(user: user)));
        },
        child: Container(
            width: 75,
            margin: EdgeInsets.symmetric(horizontal: 8),
            child: Column(children: [
              Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Color(0xFF25D366), width: 2)),
                  child: CircleAvatar(
                      radius: 28,
                      backgroundImage: user.photoURL.startsWith('http')
                          ? NetworkImage(user.photoURL) as ImageProvider
                          : AssetImage(user.photoURL))),
              SizedBox(height: 4),
              Text(user.name.split(' ')[0],
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center)
            ])));
  }

  Widget _buildCommunityHeader() {
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Colors.grey[50],
        child: Row(children: [
          Text(
            'Communities',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF128C7E),
            ),
          ),
          Spacer(),
          TextButton.icon(
              icon: Icon(Icons.add_circle_outline, color: Color(0xFF128C7E)),
              label: Text('New', style: TextStyle(color: Color(0xFF128C7E))),
              onPressed: () {})
        ]));
  }

  Widget _buildCommunityItem(Community community) {
    return ListTile(
        leading: CircleAvatar(
          backgroundImage: community.imageUrl.startsWith('http')
              ? NetworkImage(community.imageUrl) as ImageProvider
              : AssetImage(community.imageUrl),
          radius: 26,
        ),
        title: Text(
          community.name,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(children: [
          Icon(Icons.people, size: 16, color: Colors.grey[600]),
          SizedBox(width: 4),
          Expanded(
              child: Text(
                  '${community.memberCount} members • ${community.description}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13)))
        ]),
        trailing: Text(_getTimeString(community.lastActivity),
            style: TextStyle(color: Colors.grey, fontSize: 12)),
        onTap: () {});
  }

  String _getTimeString(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr';
    } else {
      return '${difference.inDays} d';
    }
  }
}
