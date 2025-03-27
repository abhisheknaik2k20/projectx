// ignore_for_file: non_constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
  String? dateTime;
  void getDetails() async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.UserUID)
        .get();
    setState(() {
      data = snapshot.data() as Map<String, dynamic>;
    });
    dateTime = data?['dob'].split(" ")[0];
    print(dateTime);
  }

  @override
  void initState() {
    getDetails();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return Center(
        child: CircularProgressIndicator(
          backgroundColor: Colors.teal.shade300,
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.teal.shade300,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 80, left: 17, right: 17),
              child: Container(
                alignment: Alignment.centerLeft,
                height: 300,
                padding: const EdgeInsets.only(
                  right: 15,
                ),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 5,
                      ),
                      // For profile imagge
                      Container(
                        width: 190,
                        height: 290,
                        decoration: BoxDecoration(
                            image: const DecorationImage(
                              image: AssetImage("assets/profile.png"),
                              fit: BoxFit.fitWidth,
                            ),
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      // for name email , date of birth and address
                      Padding(
                        padding: const EdgeInsets.only(top: 25, left: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Text(
                                data!['name'].contains(
                                        ' ') // Check if the string contains any blank spaces
                                    ? data!['name'].split(' ').join(
                                        '\n') // If yes, split the string at spaces and join with newlines
                                    : data![
                                        'name'], // If not, display the string as it is
                                style: const TextStyle(
                                    fontSize: 45,
                                    height: 0.9,
                                    color: Colors.teal),
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            const Text(
                              "Email",
                              style: TextStyle(
                                color: Colors.black45,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              data?['email'],
                              style: const TextStyle(
                                  fontSize: 20,
                                  height: 0.9,
                                  color: Colors.teal),
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            const Text(
                              "Date of Birth",
                              style: TextStyle(
                                color: Colors.black45,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              dateTime ?? 'null',
                              style: const TextStyle(
                                  fontSize: 20,
                                  height: 0.9,
                                  color: Colors.teal),
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            const Text(
                              "Address",
                              style: TextStyle(
                                color: Colors.black45,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              "Mumbai, Maharashtra",
                              style: TextStyle(
                                  fontSize: 20,
                                  height: 0.9,
                                  color: Colors.teal),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(
                  top: 20, left: 17, right: 17, bottom: 20),
              child: Container(
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 18, right: 18, left: 18),
                      child: Text(
                        "BIO",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 2, right: 18, left: 18, bottom: 20),
                      child: Text(
                        data?['bio'] ?? "Hey there I'm using Messaging App",
                        style: const TextStyle(color: Colors.teal),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 17, right: 17, bottom: 20),
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                          top: 18, right: 18, left: 18, bottom: 10),
                      child: Text(
                        "ON THE WEB",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                    ),
                    Padding(
                        padding: EdgeInsets.only(
                            top: 2, right: 18, left: 18, bottom: 20),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.teal,
                              child: Icon(
                                FontAwesomeIcons.facebookF,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(
                              width: 15,
                            ),
                            CircleAvatar(
                              backgroundColor: Colors.teal,
                              child: Icon(
                                FontAwesomeIcons.instagram,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(
                              width: 15,
                            ),
                            CircleAvatar(
                              backgroundColor: Colors.teal,
                              child: Icon(
                                FontAwesomeIcons.linkedinIn,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(
                              width: 15,
                            ),
                            CircleAvatar(
                              backgroundColor: Colors.teal,
                              child: Icon(
                                FontAwesomeIcons.twitter,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )),
                  ],
                ),
              ),
            ),
            // for websit and phone
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 17, right: 17),
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 18, right: 25, left: 18),
                      child: Row(
                        children: [
                          Text(
                            "WEBSITE",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.teal),
                          ),
                          Spacer(),
                          Text(
                            "www.example.website.com",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.teal),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 18, right: 25, left: 18),
                      child: Row(
                        children: [
                          const Text(
                            "PHONE",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.teal),
                          ),
                          const Spacer(),
                          Text(
                            "+91 ${data?['phone']}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.teal),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
