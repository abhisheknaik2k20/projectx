import 'package:SwiftTalk/CONTROLLER/Call_Provider.dart';
import 'package:SwiftTalk/CONTROLLER/Login_Logic.dart';
import 'package:SwiftTalk/CONTROLLER/Native_Implement.dart';
import 'package:SwiftTalk/CONTROLLER/NotificationService.dart';
import 'package:SwiftTalk/CONTROLLER/User_Repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:SwiftTalk/firebase_options.dart';
import 'package:SwiftTalk/VIEWS/BlackScreen.dart';
import 'package:SwiftTalk/VIEWS/Login_Screen.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;

  ThemeData get currentTheme => _isDarkMode ? _darkTheme : _lightTheme;

  final ThemeData _darkTheme = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      appBarTheme: AppBarTheme(color: Colors.teal.shade500));

  final ThemeData _lightTheme = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      appBarTheme: AppBarTheme(color: Colors.teal.shade500));

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setDarkMode(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
  print("Handling a background message: ${message.messageId}");
  if (message.data.containsKey('type') && message.data['type'] == 'VideoCall') {
    print("Showing video call notification");
    await NotificationService.showVideoCallNotification(message);
  } else {
    print("Showing normal notification");
    await NotificationService.showFlutterNotification(message);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
  await NotificationService.initialize();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: true,
      carPlay: true,
      criticalAlert: true);

  runApp(MultiProvider(providers: [
    Provider<UserRepository>(create: (_) => UserRepository()),
    ChangeNotifierProxyProvider<UserRepository, CallStatusProvider>(
        create: (context) => CallStatusProvider(context.read<UserRepository>()),
        update: (context, userRepository, previous) => previous!),
    ChangeNotifierProvider(create: (_) => AuthLoadingProvider()),
    ChangeNotifierProvider(create: (_) => ThemeProvider())
  ], child: MyApp()));
  Vibration.cancel();
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  UserRepository userRepository = UserRepository();
  FirebaseAuth auth = FirebaseAuth.instance;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupMessaging();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      super.didChangeAppLifecycleState(state);
      String status = state == AppLifecycleState.resumed
          ? 'Online'
          : 'Last seen ${CustomDateFormat.formatDateTime(DateTime.now())}';
      if (auth.currentUser?.uid != null) {
        userRepository.updateUserStatus(auth.currentUser!.uid, status);
      }
      Vibration.cancel();
      _setupMessaging();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (auth.currentUser?.uid != null) {
        userRepository.updateUserStatus(auth.currentUser!.uid,
            'Last seen ${CustomDateFormat.formatDateTime(DateTime.now())}');
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Vibration.cancel();
    super.dispose();
  }

  Future<void> _setupMessaging() async {
    UserRepository userRepository = UserRepository();
    await FirebaseMessaging.instance.subscribeToTopic('all_users');
    FirebaseMessaging.instance.onTokenRefresh
        .listen((newToken) => userRepository.updateFcmToken(newToken));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      return MaterialApp(
        navigatorKey: navigatorKey,
        title: 'SwiftTalk',
        theme: themeProvider.currentTheme,
        debugShowCheckedModeBanner: false,
        home: Consumer<AuthLoadingProvider>(builder: (context, loading, child) {
          if (loading.isLoading) {
            return Scaffold(
                body: Center(
                    child: CircularProgressIndicator(color: Colors.teal)));
          }
          return StreamBuilder(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) => switch (snapshot) {
                    AsyncSnapshot(hasData: true) => const BlackScreen(),
                    _ => const LoginSignupScreen()
                  });
        }),
      );
    });
  }
}

class SwipeableScaffoldScreen extends StatefulWidget {
  const SwipeableScaffoldScreen({super.key});

  @override
  State<SwipeableScaffoldScreen> createState() =>
      _SwipeableScaffoldScreenState();
}

class _SwipeableScaffoldScreenState extends State<SwipeableScaffoldScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragOffset = 0.0;
  bool _isOpen = false;
  final double _maxSlide = 250.0;
  final double _maxRotation = 0.3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) {}

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dx;
      _dragOffset = _dragOffset.clamp(0.0, _maxSlide);
      _controller.value = _dragOffset / _maxSlide;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (_isOpen) {
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

  void _openDrawer() {
    _controller.animateTo(1.0);
    setState(() {
      _dragOffset = _maxSlide;
      _isOpen = true;
    });
  }

  void _closeDrawer() {
    _controller.animateTo(0.0);
    setState(() {
      _dragOffset = 0.0;
      _isOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Scaffold(
            backgroundColor: Colors.indigo[700],
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('BOTTOM SCAFFOLD',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.indigo[700],
                    ),
                    onPressed: _closeDrawer,
                    child: const Text('Close Top Scaffold'),
                  ),
                ],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final slideAmount = _maxSlide * _controller.value;
              final rotateAmount = _maxRotation * _controller.value;
              return Transform(
                transform: Matrix4.identity()
                  ..translate(slideAmount)
                  ..rotateZ(rotateAmount),
                alignment: Alignment.centerLeft,
                child: child,
              );
            },
            child: GestureDetector(
              onHorizontalDragStart: _onDragStart,
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              behavior: HitTestBehavior.translucent,
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('Swipeable Scaffold Demo'),
                  backgroundColor: Colors.blue,
                  leading: IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: _isOpen ? _closeDrawer : _openDrawer,
                  ),
                ),
                body: Container(
                  color: Colors.white,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'TOP SCAFFOLD',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Swipe right to reveal bottom scaffold',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Swipe left to close',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
}
