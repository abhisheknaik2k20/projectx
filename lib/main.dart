import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:projectx/firebase_options.dart';
import 'package:projectx/pages/BlackScreen.dart';
import 'package:projectx/pages/Login/login_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _configureLocalNotifications();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.android,
  );
  //FirebaseApi().initNotifications();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project-X',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        appBarTheme: AppBarTheme(color: Colors.teal.shade500),
      ),
      debugShowCheckedModeBanner: false,
      home: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) => switch (snapshot) {
                AsyncSnapshot(hasData: true) => const BlackScreen(),
                _ => const LoginSignupScreen()
              }),
    );
  }
}

void _configureLocalNotifications() {
  var initializationSettingsAndroid =
      const AndroidInitializationSettings('@mipmap/ic_launcher');
  var initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  flutterLocalNotificationsPlugin.initialize(initializationSettings);
}
