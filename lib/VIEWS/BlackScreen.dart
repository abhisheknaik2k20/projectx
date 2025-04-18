import 'package:SwiftTalk/CONTROLLER/Call_Provider.dart';
import 'package:SwiftTalk/VIEWS/Community.dart';
import 'package:SwiftTalk/main.dart';
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
import 'dart:math' as math;

class BlackScreen extends StatefulWidget {
  const BlackScreen({super.key});
  @override
  State<BlackScreen> createState() => _BlackScreenState();
}

class _BlackScreenState extends State<BlackScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  double _dragOffset = 0.0;
  bool _isDrawerOpen = false;
  final double _maxSlide = 250.0;
  final double _maxRotation = 0.15;
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance.collection('users');
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    if (_isDrawerOpen) {
      _closeDrawer();
    } else {
      _openDrawer();
    }
  }

  void _hideDrawer() {
    if (_isDrawerOpen) {
      _closeDrawer();
    }
  }

  void _openDrawer() {
    _animationController.animateTo(1.0);
    setState(() {
      _dragOffset = _maxSlide;
      _isDrawerOpen = true;
    });
  }

  void _closeDrawer() {
    _animationController.animateTo(0.0);
    setState(() {
      _dragOffset = 0.0;
      _isDrawerOpen = false;
    });
  }

  void _navigateTo(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (context) => page));

  void _onDragStart(DragStartDetails details) {
    // Store initial drag position if needed
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dx;
      _dragOffset = _dragOffset.clamp(0.0, _maxSlide);
      _animationController.value = _dragOffset / _maxSlide;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (_isDrawerOpen) {
      if (velocity < -500 || _dragOffset < _maxSlide / 2) {
        _closeDrawer();
      } else {
        _openDrawer();
      }
    } else {
      if (velocity > 500 || _dragOffset > _maxSlide / 2) {
        _openDrawer();
      } else {
        _closeDrawer();
      }
    }
  }

  List<ListTile> get _drawerItems {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return [
      _buildDrawerItem(
          icon: Icons.home, title: 'Home', onTap: () => _hideDrawer()),
      _buildDrawerItem(
          icon: Icons.account_circle_rounded,
          title: 'Profile',
          onTap: () => _navigateTo(
              ProfilePage(UserUID: _auth.currentUser!.uid, isMe: true))),
      _buildDrawerItem(icon: Icons.computer, title: 'WEB-Login', onTap: () {}),
      _buildDrawerItem(
          icon: themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
          title: themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
          onTap: () {
            themeProvider.toggleTheme();
            _hideDrawer();
          }),
      _buildDrawerItem(
          icon: Icons.power_settings_new,
          title: 'Log-Out',
          onTap: () => _auth.signOut())
    ];
  }

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
              colors: [Colors.grey.shade900, Colors.black])),
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

    return Stack(children: [
      Scaffold(body: _buildDrawerContent()),
      AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final slideAmount = _maxSlide * _animationController.value;
            final rotateAmount = _maxRotation * _animationController.value;
            return Transform(
                transform: Matrix4.identity()
                  ..translate(slideAmount)
                  ..rotateZ(rotateAmount),
                alignment: Alignment.centerLeft,
                child: child);
          },
          child: GestureDetector(
              onHorizontalDragStart: _onDragStart,
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              behavior: HitTestBehavior.translucent,
              child: Scaffold(
                  body: callStatusProvider.isCallActive
                      ? const CallScreen()
                      : HomePage(toggleDrawer: _toggleDrawer))))
    ]);
  }
}

class HomePage extends StatefulWidget {
  final VoidCallback toggleDrawer;
  const HomePage({required this.toggleDrawer, super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<double> valueNotifier = ValueNotifier(1.0);
  final _auth = FirebaseAuth.instance;
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _appBarAnimation;
  int _selectedIndex = 0;
  int _previousIndex = 0;
  late List<Map<dynamic, dynamic>> _pagesInfo = [];
  final _navItems = [
    const BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Chat'),
    const BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Status'),
    const BottomNavigationBarItem(
        icon: Icon(Icons.notifications_active), label: 'Notifications'),
    const BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: 'BOT')
  ];
  double _navBarVal = 1.0;
  bool _showNavBar = true;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _initializePagesInfo();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _animationController.value = 1.0;
    _appBarAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _pageController = PageController(initialPage: _selectedIndex);
    _initializeApp();
  }

  void _initializePagesInfo() => _pagesInfo = [
        {
          'APPBARINFO': {
            'title': 'CHATS',
            'IconButtons': {
              IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.search, color: Colors.white)),
              IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.more_vert, color: Colors.white))
            }
          },
          'PAGE': MessagesPage(toggleDrawer: widget.toggleDrawer)
        },
        {
          'APPBARINFO': {
            'title': 'STATUS',
            'IconButtons': {
              IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.search, color: Colors.white)),
              IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.more_vert, color: Colors.white))
            }
          },
          'PAGE':
              WhatsAppStatusCommunityScreen(toggleDrawer: widget.toggleDrawer)
        },
        {
          'APPBARINFO': {
            'title': 'NOTIFICATIONS',
            'IconButtons': {
              IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.search, color: Colors.white)),
              IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.more_vert, color: Colors.white))
            }
          },
          'PAGE': NotificationPage(toggleDrawer: widget.toggleDrawer)
        },
        {
          'APPBARINFO': {
            'title': Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const CircleAvatar(
                      backgroundColor: Colors.white,
                      child:
                          Icon(Icons.smart_toy_outlined, color: Colors.teal)),
                  const SizedBox(width: 10),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('CHATBOT',
                            style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        Text('Online',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[200],
                                fontWeight: FontWeight.bold))
                      ])
                ])
          },
          'PAGE': ChatGPTScreen(valueNotifier: valueNotifier)
        }
      ];

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

    final newIndex = page.round();
    if (newIndex != _selectedIndex) {
      _previousIndex = _selectedIndex;
      setState(() => _selectedIndex = newIndex);
      if (!_isAnimating) {
        _isAnimating = true;
        _animationController.forward(from: 0.0).then((_) {
          _isAnimating = false;
        });
      }
    }
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

  void _navigateToPage(int index) {
    if (_selectedIndex == index) return;
    _previousIndex = _selectedIndex;
    _isAnimating = true;
    _animationController.forward(from: 0.0).then((_) => _isAnimating = false);
    _pageController.animateToPage(index,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic);
  }

  @override
  void dispose() {
    valueNotifier.dispose();
    _pageController.removeListener(_handlePageChange);
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildTitleWidget(dynamic titleContent) {
    if (titleContent is String) {
      return Text(titleContent,
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20));
    } else {
      return titleContent;
    }
  }

  PreferredSizeWidget _buildAppBar() {
    final currentAppBarInfo = _pagesInfo[_selectedIndex]['APPBARINFO'];
    final previousAppBarInfo = _pagesInfo[_previousIndex]['APPBARINFO'];
    final isChatBotPage = _selectedIndex == 3;
    final chatBotPageOffset = _pageController.hasClients &&
            _pageController.page != null
        ? 1.0 - math.min(1.0, math.max(0.0, (3 - _pageController.page!).abs()))
        : (isChatBotPage ? 1.0 : 0.0);
    final animationValue = _isAnimating ? _appBarAnimation.value : 1.0;
    return PreferredSize(
        preferredSize: Size.fromHeight(50),
        child: AnimatedBuilder(
            animation: _appBarAnimation,
            builder: (context, child) => AppBar(
                backgroundColor: Colors.teal.shade500,
                elevation: 4 * animationValue,
                toolbarHeight: 50,
                leadingWidth: 56 * (1 - chatBotPageOffset),
                leading: chatBotPageOffset >= 0.99
                    ? null
                    : SizedBox(
                        width: 56 * (1 - chatBotPageOffset),
                        child: Opacity(
                            opacity: 1 - chatBotPageOffset,
                            child: IconButton(
                                icon: Icon(Icons.menu, color: Colors.white),
                                onPressed: widget.toggleDrawer))),
                titleSpacing: 0,
                title: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.only(left: chatBotPageOffset * 16),
                    child: Container(
                        height: 50,
                        alignment: Alignment.centerLeft,
                        child:
                            Stack(alignment: Alignment.centerLeft, children: [
                          Opacity(
                              opacity: 1 - animationValue,
                              child: Transform.translate(
                                  offset: Offset(-20 * animationValue, 0),
                                  child: _buildTitleWidget(
                                      previousAppBarInfo['title']))),
                          Opacity(
                              opacity: animationValue,
                              child: Transform.translate(
                                  offset: Offset(20 * (1 - animationValue), 0),
                                  child: _buildTitleWidget(
                                      currentAppBarInfo['title'])))
                        ]))),
                actions: currentAppBarInfo.containsKey('IconButtons')
                    ? List<Widget>.from(
                        (currentAppBarInfo['IconButtons'] as Set<IconButton>)
                            .map((button) => Opacity(
                                // Use 1.0 opacity when app is first loaded
                                opacity: _isAnimating ? animationValue : 1.0,
                                child: button)))
                    : [])));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: _buildAppBar(),
      body: PageView.builder(
          controller: _pageController,
          itemCount: _pagesInfo.length,
          itemBuilder: (context, index) => _pagesInfo[index]['PAGE']),
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
                            onTap: _navigateToPage,
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
