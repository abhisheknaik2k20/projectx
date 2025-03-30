import 'package:SwiftTalk/CONTROLLER/Call_Provider.dart';
import 'package:SwiftTalk/CONTROLLER/User_Repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:SwiftTalk/firebase_options.dart';
import 'package:SwiftTalk/VIEWS/BlackScreen.dart';
import 'package:SwiftTalk/VIEWS/login_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
  print("Handling a background message: ${message.messageId}");
  print("Background message data: ${message.data}");
  print("Background notification: ${message.notification?.title}");

  await setupFlutterNotifications();
  await showFlutterNotification(message);
}

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important notifications.',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
  showBadge: true,
  enableLights: true,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Setup method for notification plugin
Future<void> setupFlutterNotifications() async {
  // Only initialize once
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Configure iOS settings
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // Initialize settings for both platforms
  const InitializationSettings initSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      defaultPresentSound: true,
    ),
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      // Handle notification tap
      print("Notification tapped: ${response.payload}");
      // Navigate if needed based on payload
    },
  );
}

Future<void> showFlutterNotification(RemoteMessage message) async {
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;
  print("Showing notification: ${notification?.title}");
  if (notification != null) {
    flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title ?? 'SwiftTalk Notification',
        notification.body ?? 'You have a new notification',
        NotificationDetails(
            android: AndroidNotificationDetails(channel.id, channel.name,
                channelDescription: channel.description,
                icon: android?.smallIcon ?? 'mipmap/ic_launcher',
                playSound: true,
                enableVibration: true,
                priority: Priority.high,
                importance: Importance.high),
            iOS: const DarwinNotificationDetails(
                presentSound: true,
                presentAlert: true,
                presentBadge: true,
                sound: 'notification_sound.aiff')),
        payload: message.data.toString());
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.android);

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Set up notifications
  await setupFlutterNotifications();

  // Request permissions
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
        update: (context, userRepository, previous) => previous!)
  ], child: MyApp()));
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
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      showFlutterNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A notification was tapped: ${message.data}');
      // Navigate to specific screen based on message if needed
    });

    // Check for initial notification (app opened from terminated state)
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        print(
            'App opened from terminated state via notification: ${message.data}');
        // Navigate to specific screen based on message if needed
      }
    });

    _setupMessaging();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      super.didChangeAppLifecycleState(state);
      String status = state == AppLifecycleState.resumed
          ? 'Online'
          : 'Last seen ${DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now())}';
      if (auth.currentUser?.uid != null) {
        userRepository.updateUserStatus(auth.currentUser!.uid, status);
      }
      _setupMessaging();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
    return MaterialApp(
        navigatorKey: navigatorKey,
        title: 'SwiftTalk',
        theme: ThemeData(
            useMaterial3: true,
            appBarTheme: AppBarTheme(color: Colors.teal.shade500)),
        debugShowCheckedModeBanner: false,
        home: StreamBuilder(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) => switch (snapshot) {
                  AsyncSnapshot(hasData: true) => const BlackScreen(),
                  _ => const LoginSignupScreen()
                }));
  }
}
