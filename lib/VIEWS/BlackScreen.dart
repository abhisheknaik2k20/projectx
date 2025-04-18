import 'package:SwiftTalk/CONTROLLER/Call_Provider.dart';
import 'package:SwiftTalk/VIEWS/Community.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:SwiftTalk/VIEWS/Call_Screen.dart';
import 'package:SwiftTalk/VIEWS/NotificationPage.dart';
import 'package:SwiftTalk/VIEWS/Profile.dart';
import 'package:SwiftTalk/VIEWS/Chat_Bot.dart';
import 'package:SwiftTalk/VIEWS/Main_Screen.dart';
import 'package:provider/provider.dart';

class BlackScreen extends StatefulWidget {
  const BlackScreen({super.key});
  @override
  State<BlackScreen> createState() => _BlackScreenState();
}

class _BlackScreenState extends State<BlackScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance.collection('users');

  void _toggleDrawer() {
    if (_scaffoldKey.currentState!.isDrawerOpen) {
      _scaffoldKey.currentState!.closeDrawer();
    } else {
      _scaffoldKey.currentState!.openDrawer();
    }
  }

  void _hideDrawer() {
    if (_scaffoldKey.currentState!.isDrawerOpen) {
      _scaffoldKey.currentState!.closeDrawer();
    }
  }

  void _navigateTo(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (context) => page));

  List<ListTile> get _drawerItems => [
        _buildDrawerItem(
            icon: Icons.home, title: 'Home', onTap: () => _hideDrawer()),
        _buildDrawerItem(
            icon: Icons.account_circle_rounded,
            title: 'Profile',
            onTap: () => _navigateTo(
                ProfilePage(UserUID: _auth.currentUser!.uid, isMe: true))),
        _buildDrawerItem(
            icon: Icons.computer, title: 'WEB-Login', onTap: () {}),
        _buildDrawerItem(
            icon: Icons.power_settings_new,
            title: 'Log-Out',
            onTap: () => _auth.signOut())
      ];

  ListTile _buildDrawerItem(
          {required IconData icon,
          required String title,
          required VoidCallback onTap}) =>
      ListTile(onTap: onTap, leading: Icon(icon), title: Text(title));

  Widget _buildDrawerContent() => Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.grey.shade800, Colors.black])),
      child: SafeArea(
          child: ListTileTheme(
              textColor: Colors.white,
              iconColor: Colors.white,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(height: 30),
                    StreamBuilder<DocumentSnapshot>(
                        stream: _db.doc(_auth.currentUser?.uid).snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            final userData =
                                snapshot.data!.data() as Map<String, dynamic>?;
                            final profileUrl = userData?['photoURL'] ??
                                _auth.currentUser?.photoURL;
                            return profileUrl != null
                                ? CircleAvatar(
                                    backgroundImage: NetworkImage(profileUrl),
                                    radius: 45)
                                : const Icon(Icons.account_circle,
                                    size: 100, color: Colors.white);
                          } else {
                            return _auth.currentUser?.photoURL != null
                                ? CircleAvatar(
                                    backgroundImage: NetworkImage(
                                        _auth.currentUser!.photoURL!),
                                    radius: 45)
                                : const Icon(Icons.account_circle,
                                    size: 100, color: Colors.white);
                          }
                        }),
                    SizedBox(height: 10),
                    Wrap(children: [
                      Text(_auth.currentUser?.displayName ?? 'Unknown User',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                          overflow: TextOverflow.ellipsis)
                    ]),
                    SizedBox(height: 10),
                    ..._drawerItems,
                    const Spacer(),
                    const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('Terms of Service | Privacy Policy',
                            style:
                                TextStyle(fontSize: 12, color: Colors.white54)))
                  ]))));

  @override
  Widget build(BuildContext context) {
    final callStatusProvider = context.watch<CallStatusProvider>();
    Widget mainContent = callStatusProvider.isCallActive
        ? const CallScreen()
        : HomePage(toggleDrawer: _toggleDrawer);
    return Scaffold(
        key: _scaffoldKey,
        drawer: Drawer(
            width: MediaQuery.of(context).size.width * 0.75,
            child: _buildDrawerContent()),
        body: mainContent);
  }
}

class HomePage extends StatefulWidget {
  final VoidCallback toggleDrawer;
  const HomePage({required this.toggleDrawer, super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ValueNotifier<double> valueNotifier = ValueNotifier(1.0);
  final _auth = FirebaseAuth.instance;
  late PageController _pageController;
  int _selectedIndex = 0;
  late List<Widget> _pages = [];
  final _navItems = [
    const BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Chat'),
    const BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Status'),
    const BottomNavigationBarItem(
        icon: Icon(Icons.notifications_active), label: 'Notifications'),
    const BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: 'BOT')
  ];

  double _navBarVal = 1.0;
  bool _showNavBar = true;

  @override
  void initState() {
    super.initState();
    _pages = [
      MessagesPage(toggleDrawer: widget.toggleDrawer),
      WhatsAppStatusCommunityScreen(),
      NotificationPage(toggleDrawer: widget.toggleDrawer),
      ChatGPTScreen(valueNotifier: valueNotifier)
    ];
    _pageController = PageController(initialPage: _selectedIndex);
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _requestContactsPermission();
    await _reloadUser();
    _pageController.addListener(_handlePageChange);
  }

  void _handlePageChange() {
    if (!mounted) return;
    final page = _pageController.page;
    if (page == null) return;
    final distanceToChatBot = (page - 3).abs();
    if (distanceToChatBot <= 1) {
      final animationValue = distanceToChatBot.clamp(0.0, 1.0);
      setState(() {
        _navBarVal = animationValue;
        valueNotifier.value = 1 - animationValue;
        _showNavBar = animationValue > 0.1;
      });
    } else {
      setState(() {
        _navBarVal = 1.0;
        _showNavBar = true;
      });
    }
    setState(() => _selectedIndex = page.round());
  }

  Future<void> _requestContactsPermission() async =>
      await Permission.contacts.request();

  Future<void> _reloadUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      await user.reload();
      await user.getIdToken();
    } catch (_) {}
  }

  @override
  void dispose() {
    valueNotifier.dispose();
    _pageController.removeListener(_handlePageChange);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(backgroundColor: Colors.teal.shade500, toolbarHeight: 0),
      backgroundColor: Colors.white,
      body: PageView.builder(
          controller: _pageController,
          itemCount: _pages.length,
          physics: const PageScrollPhysics(),
          itemBuilder: (context, index) => _pages[index]),
      bottomNavigationBar: _showNavBar
          ? AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              height: 72 * _navBarVal,
              color: Colors.grey.shade900,
              child: ClipRect(
                  child: OverflowBox(
                      maxHeight: 72,
                      minHeight: 0,
                      alignment: Alignment.center,
                      child: Theme(
                        data: Theme.of(context).copyWith(
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent),
                        child: BottomNavigationBar(
                            currentIndex: _selectedIndex,
                            onTap: (index) => _pageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.ease),
                            backgroundColor: Colors.grey.shade900,
                            unselectedItemColor: Colors.grey,
                            selectedItemColor: Colors.white,
                            showSelectedLabels: true,
                            showUnselectedLabels: true,
                            type: BottomNavigationBarType.fixed,
                            selectedFontSize: 12,
                            unselectedFontSize: 12,
                            iconSize: 24,
                            elevation: 0,
                            items: _navItems),
                      ))))
          : const SizedBox.shrink());
}
