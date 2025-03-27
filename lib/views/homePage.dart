import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:projectx/pages/ChatInterface/chatgpt.dart';
import 'package:projectx/pages/NotificationsPage/NotificationPage.dart';
import 'package:projectx/pages/messages.dart';

import 'package:intl/intl.dart';

// ignore: must_be_immutable
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

var selectedindex = 0;

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  User? user = FirebaseAuth.instance.currentUser;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore db = FirebaseFirestore.instance;

  bool isLoading = true;
  bool isSearchVisible = false;
  late PageController _pageController;

  Future<void> getContactsPermission() async {
    if (await Permission.contacts.isGranted) {
    } else {
      await Permission.contacts.request();
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController(initialPage: selectedindex);
    reloadUser();
    getContactsPermission();
    _pageController.addListener(() {
      setState(() {
        selectedindex = _pageController.page!.round();
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setStatus('Online');
    } else {
      DateTime now = DateTime.now();
      setStatus('Last seen ${DateFormat('yyyy-MM-dd hh:mm a').format(now)}');
    }
    super.didChangeAppLifecycleState(state);
  }

  void setStatus(String status) async {
    await db
        .collection('users')
        .doc(_auth.currentUser?.uid)
        .update({'status': status});
  }

  Future<void> reloadUser() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        await user.reload();
        await user.getIdToken();
        user = FirebaseAuth.instance.currentUser;
      } catch (e) {
        //  print('Error reloading user: $e');
      }
    } else {
      //   print('User is not signed in.');
    }
  }

  final pages = [
    const MessagesPage(),
    const NotificationPage(),
    const ChatGPTScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Scaffold(
              appBar: AppBar(
                leading: null,
                backgroundColor: Colors.teal.shade500,
                toolbarHeight: 0,
              ),
              backgroundColor: Colors.white,
              body: PageView.builder(
                itemCount: pages.length,
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    selectedindex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return pages[index];
                },
              ),
              bottomNavigationBar: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10.0, vertical: 10),
                  child: GNav(
                    selectedIndex: selectedindex,
                    onTabChange: (index) {
                      _pageController.animateToPage(index,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.ease);
                      setState(() {
                        selectedindex = index;
                      });
                    },
                    backgroundColor: Colors.grey.shade900,
                    color: Colors.white,
                    activeColor: Colors.white,
                    tabBackgroundColor: Colors.grey.shade800,
                    gap: 10,
                    padding: const EdgeInsets.all(16),
                    tabs: const [
                      GButton(icon: Icons.message, text: 'Chat'),
                      GButton(
                          icon: Icons.notifications_active,
                          text: 'notifications'),
                      GButton(icon: Icons.android, text: 'ChatGPT'),
                      GButton(icon: Icons.contacts, text: 'Contacts'),
                    ],
                  ),
                ),
              ),
            );
          } else {
            return Scaffold(
              body: Container(
                decoration: BoxDecoration(
                  color: Colors.teal.shade500,
                ),
                child: Center(
                  child: Image.asset(
                    'assets/chat3.png',
                    width: 300,
                  ),
                ),
              ),
            );
          }
        });
  }
}
