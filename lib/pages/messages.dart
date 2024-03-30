import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:faker/faker.dart';
import 'package:projectx/pages/ChatInterface/ChatScreen.dart';
import 'package:projectx/pages/chatScreen.dart';
import 'package:projectx/pages/messagedata.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({
    super.key,
  });

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  bool isVisible = false;
  Future<bool> _onWillPop() async {
    if (isVisible) {
      setState(() {
        isVisible = false;
      });
      return false;
    }
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Are you sure?'),
            content: const Text('Do you want to exit an App'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
        )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Column(
        children: [
          Container(
            color: Colors.teal.shade500,
            child: Padding(
              padding: const EdgeInsets.only(top: 15.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.menu,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                  Expanded(
                    child: isVisible
                        ? Container(
                            decoration:
                                BoxDecoration(color: Colors.teal.shade500),
                            child: TextFormField(
                              style: const TextStyle(color: Colors.white),
                              cursorColor: Colors.white,
                              decoration: const InputDecoration(
                                hintText: 'Search',
                                fillColor: Colors.transparent,
                                border: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                              ),
                            ))
                        : Container(
                            alignment: Alignment.center,
                            child: Text(
                              "Messaging App",
                              style: GoogleFonts.anton(
                                  color: Colors.white,
                                  fontSize: 30,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ]),
                            ),
                          ),
                  ),
                  Container(
                    child: IconButton(
                      onPressed: () {
                        setState(
                          () {
                            isVisible = !isVisible;
                          },
                        );
                      },
                      icon: const Icon(Icons.search,
                          color: Colors.white, size: 30),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            color: Colors.teal.shade500,
            child: Padding(
                padding: const EdgeInsets.only(left: 10, top: 5.0, bottom: 5.0),
                child: Container(
                  alignment: Alignment.topLeft,
                  child: Text(
                    "Verified Users :",
                    style: GoogleFonts.ptSansCaption(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 15),
                  ),
                )),
          ),
          Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 7),
                    )
                  ],
                  color: Colors.teal.shade500,
                  border: Border.all(color: Colors.teal.shade500),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(100),
                  )),
              child: _buildUsersList()),
          Container(
              width: double.maxFinite,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Text("Friend List",
                    style: GoogleFonts.ptSans(fontWeight: FontWeight.bold)),
              )),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_delegate),
                    childCount: 25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _delegate(BuildContext context, int index) {
    final Faker faker = Faker();
    return MessageTileTwo(
      messageData: MessageData(
        sendname: faker.person.name(),
        sendmessage: faker.lorem.sentence(),
      ),
    );
  }

  Widget _buildUsersList() {
    return SizedBox(
      height: 120,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('Error');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
              color: Colors.white,
            ));
          }
          return ListView(
            scrollDirection: Axis.horizontal,
            children: snapshot.data!.docs
                .map((doc) => _buildUsersListItem(doc, context))
                .toList(),
          );
        },
      ),
    );
  }

  Widget _buildUsersListItem(DocumentSnapshot document, BuildContext context) {
    final auth = FirebaseAuth.instance;
    Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
    if (auth.currentUser!.uid != data['uid']) {
      return MessageTile(
        messageData: MessageData(
          sendname: data['username'],
          sendmessage: '',
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: ((context) => ChatPage(
                    receiverName: data['name'],
                    receiverEmail: data['email'],
                    receiverUid: data['uid'],
                  )),
            ),
          );
        },
      );
    } else {
      return Container();
    }
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
      child: Container(
        child: Column(
          children: [
            const Expanded(
              child: Icon(Icons.account_circle,
                  size: 80, color: Color.fromARGB(255, 13, 2, 77)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                messageData.sendname,
                style: GoogleFonts.ptSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
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
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(messageData: messageData),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(
          left: 5,
          right: 5,
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade400,
              ),
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: CircleAvatar(
                  backgroundColor: Colors.teal.shade500,
                  child: const Icon(Icons.account_circle, size: 40),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      messageData.sendname,
                      style: GoogleFonts.ptSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      messageData.sendmessage,
                      style: GoogleFonts.ptSans(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
