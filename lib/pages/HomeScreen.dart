import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:projectx/pages/CAllScreen/callScreen.dart';
import 'package:projectx/pages/Profile.dart';
import 'package:projectx/pages/QRScanner/QRScanner.dart';
import 'package:projectx/views/homePage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void dispose() {
    _advancedDrawerController.dispose();
    super.dispose();
  }

  final _advancedDrawerController = AdvancedDrawerController();
  final db = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  var isVisible = true;
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return AdvancedDrawer(
      backdrop: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey.shade800,
              Colors.black,
            ],
          ),
        ),
      ),
      controller: _advancedDrawerController,
      animationCurve: Curves.easeInOut,
      animationDuration: const Duration(milliseconds: 300),
      animateChildDecoration: true,
      rtlOpening: false,
      disabledGestures: false,
      childDecoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      drawer: SafeArea(
        child: ListTileTheme(
          textColor: Colors.white,
          iconColor: Colors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                width: 100.0,
                height: 100.0,
                margin: const EdgeInsets.only(
                  top: 24.0,
                  bottom: 64.0,
                ),
                child: const Icon(
                  Icons.account_circle,
                  size: 100,
                  color: Colors.white,
                ),
              ),
              ListTile(
                onTap: () {
                  _advancedDrawerController.hideDrawer();
                },
                leading: const Icon(
                  Icons.home,
                ),
                title: const Text('Home'),
              ),
              ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ProfilePage(
                              UserUID: FirebaseAuth.instance.currentUser!.uid,
                            )),
                  );
                },
                leading: const Icon(Icons.account_circle_rounded),
                title: const Text('Profile'),
              ),
              ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QRScanner(),
                    ),
                  );
                },
                leading: const Icon(Icons.computer),
                title: const Text('WEB-Login'),
              ),
              ListTile(
                onTap: () {
                  FirebaseAuth.instance.signOut();
                },
                leading: const Icon(
                  Icons.power_settings_new,
                ),
                title: const Text('Log-Out'),
              ),
              const Spacer(),
              DefaultTextStyle(
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 16.0,
                  ),
                  child: const Text('Terms of Service | Privacy Policy'),
                ),
              ),
            ],
          ),
        ),
      ),
      child: StreamBuilder(
          stream: db.collection('users').doc(auth.currentUser!.uid).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.data?.data()?['isCall'] != null) {
              if (snapshot.data?.data()?['isCall'] != false) {
                isVisible = false;
                return const CallScreen();
              }
            }
            isVisible = true;
            return Stack(children: [
              const HomePage(),
              isVisible
                  ? Positioned(
                      top: screenHeight * 0.05,
                      left: screenWidth * 0.02,
                      child: IconButton(
                        icon: const Icon(
                          null,
                          color: Colors.white,
                          size: 40,
                        ),
                        onPressed: () {
                          _handleMenuButtonPressed();
                        },
                      ))
                  : Container(),
            ]);
          }),
    );
  }

  void _handleMenuButtonPressed() {
    _advancedDrawerController.showDrawer();
  }
}
