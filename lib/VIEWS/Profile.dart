import 'package:SwiftTalk/CONTROLLER/Call_Provider.dart';
import 'package:SwiftTalk/VIEWS/Call_Screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  final String UserUID;
  const ProfilePage({
    super.key,
    required this.UserUID,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? data;
  String? formattedDateTime;

  void getDetails() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.UserUID)
          .get();

      setState(() {
        data = snapshot.data() as Map<String, dynamic>?;

        // Handle Timestamp conversion
        if (data?['createdAt'] is Timestamp) {
          Timestamp timestamp = data?['createdAt'] as Timestamp;
          formattedDateTime =
              DateFormat('dd MMM yyyy').format(timestamp.toDate());
        } else if (data?['createdAt'] is String) {
          // Fallback for string timestamps
          formattedDateTime = data?['createdAt'];
        } else {
          formattedDateTime = 'Not available';
        }
      });
    } catch (e) {
      print('Error fetching user details: $e');
      setState(() {
        formattedDateTime = 'Error loading date';
      });
    }
  }

  @override
  void initState() {
    getDetails();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final callStatusProvider = context.watch<CallStatusProvider>();
    if (callStatusProvider.isCallActive) {
      return const CallScreen();
    }

    if (data == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.teal),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Text(
          'Profile',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop()),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.edit,
              size: 28,
              color: Colors.white,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            color: Colors.teal.shade50,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.green.shade100,
                  child: data?['photoURL'] != null
                      ? ClipOval(
                          child: Image.network(
                            data!['photoURL'],
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: Colors.teal,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.account_circle,
                                size: 140,
                                color: Colors.teal,
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.account_circle,
                          size: 140,
                          color: Colors.teal,
                        ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data!['name'] ?? 'No Name',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          data?['email'] ?? 'No email',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Profile Details Section
          _buildProfileSection([
            _buildDetailRow(
              'Phone',
              data?['phone'] != "null"
                  ? '+91 ${data?['phone']}'
                  : 'Not available',
            ),
            _buildDetailRow('Last Login', formattedDateTime ?? 'Not available'),
            _buildDetailRow('Address', 'Mumbai, Maharashtra'),
          ]),

          // Bio Section
          _buildProfileSection([
            const Text(
              'About',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              data?['bio'] ?? "Hey there, I'm using Messaging App",
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ]),

          // Social Media Links
          _buildProfileSection([
            const Text(
              'On the Web',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSocialIcon(FontAwesomeIcons.facebook),
                _buildSocialIcon(FontAwesomeIcons.instagram),
                _buildSocialIcon(FontAwesomeIcons.linkedin),
                _buildSocialIcon(FontAwesomeIcons.twitter),
              ],
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildProfileSection(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  // Helper method to build detail rows
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build social media icons
  Widget _buildSocialIcon(IconData icon) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: Colors.teal,
      child: Icon(
        icon,
        color: Colors.white,
        size: 22,
      ),
    );
  }
}
