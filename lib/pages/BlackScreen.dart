import 'package:SwiftTalk/pages/CallScreen/Call_Provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:SwiftTalk/pages/CallScreen/Call_Screen.dart';
import 'package:SwiftTalk/pages/NotificationsPage/NotificationPage.dart';
import 'package:SwiftTalk/pages/Profile.dart';
import 'package:SwiftTalk/pages/QRScanner/QRScanner.dart';
import 'package:SwiftTalk/pages/Chat_Bot.dart';
import 'package:SwiftTalk/pages/Main_Screen.dart';
import 'package:provider/provider.dart';

class BlackScreen extends StatefulWidget {
  const BlackScreen({super.key});

  @override
  State<BlackScreen> createState() => _BlackScreenState();
}

class _BlackScreenState extends State<BlackScreen> {
  final _drawerController = AdvancedDrawerController();
  final _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _drawerController.dispose();
    super.dispose();
  }

  void _navigateTo(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (context) => page));

  List<ListTile> get _drawerItems => [
        _buildDrawerItem(
            icon: Icons.home,
            title: 'Home',
            onTap: () => _drawerController.hideDrawer()),
        _buildDrawerItem(
            icon: Icons.account_circle_rounded,
            title: 'Profile',
            onTap: () =>
                _navigateTo(ProfilePage(UserUID: _auth.currentUser!.uid))),
        _buildDrawerItem(
            icon: Icons.computer,
            title: 'WEB-Login',
            onTap: () => _navigateTo(const QRScanner())),
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

  Widget _buildDrawerContent() {
    return SafeArea(
        child: ListTileTheme(
            textColor: Colors.white,
            iconColor: Colors.white,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Icon(
                    Icons.account_circle,
                    size: 100,
                    color: Colors.white,
                  ),
                  ..._drawerItems,
                  const Spacer(),
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('Terms of Service | Privacy Policy',
                          style:
                              TextStyle(fontSize: 12, color: Colors.white54)))
                ])));
  }

  Widget _buildDrawerBackdrop() {
    return Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.grey.shade800, Colors.black])));
  }

  @override
  Widget build(BuildContext context) {
    final callStatusProvider = context.watch<CallStatusProvider>();
    return AdvancedDrawer(
      backdrop: _buildDrawerBackdrop(),
      controller: _drawerController,
      animationCurve: Curves.easeInOut,
      animationDuration: const Duration(milliseconds: 300),
      drawer: _buildDrawerContent(),
      child: callStatusProvider.isCallActive
          ? const CallScreen()
          : HomePage(dc: _drawerController),
    );
  }
}

class HomePage extends StatefulWidget {
  final AdvancedDrawerController dc;
  const HomePage({required this.dc, super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  late PageController _pageController;
  int _selectedIndex = 0;
  late List<Widget> _pages = [];
  final _navItems = [
    const GButton(icon: Icons.message, text: 'Chat'),
    const GButton(icon: Icons.notifications_active, text: 'notifications'),
    const GButton(icon: Icons.smart_toy, text: 'BOT')
  ];

  double _navBarVal = 1.0;
  bool _showNavBar = true;

  @override
  void initState() {
    super.initState();
    _pages = [
      MessagesPage(dc: widget.dc),
      NotificationPage(dc: widget.dc),
      const ChatGPTScreen()
    ];
    WidgetsBinding.instance.addObserver(this);
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
    final distanceToChatBot = (page - 2).abs();
    if (distanceToChatBot <= 1) {
      final animationValue = distanceToChatBot.clamp(0.0, 1.0);
      setState(() {
        _navBarVal = animationValue;
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _db.collection('users').doc(_auth.currentUser?.uid).update({
      'status': state == AppLifecycleState.resumed
          ? 'Online'
          : 'Last seen ${DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now())}'
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.removeListener(_handlePageChange);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(backgroundColor: Colors.teal.shade500, toolbarHeight: 0),
        backgroundColor: Colors.white,
        body: PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            physics: const PageScrollPhysics(),
            itemBuilder: (context, index) => _pages[index]),
        bottomNavigationBar: _showNavBar
            ? AnimatedContainer(
                duration: const Duration(microseconds: 300),
                height: 76 * _navBarVal,
                decoration: BoxDecoration(color: Colors.grey.shade900),
                child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    child: GNav(
                        selectedIndex: _selectedIndex,
                        onTabChange: (index) {
                          _pageController.animateToPage(index,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.ease);
                        },
                        backgroundColor: Colors.grey.shade900,
                        color: Colors.white,
                        activeColor: Colors.white,
                        tabBackgroundColor: Colors.grey.shade800,
                        gap: 10,
                        padding: const EdgeInsets.all(16),
                        tabs: _navItems)))
            : const SizedBox.shrink());
  }
}
