import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:projectx/api/firebase_api.dart';
import 'package:projectx/firebase_options.dart';
import 'package:projectx/pages/HomeScreen.dart';
import 'package:projectx/views/homePage.dart';
import 'package:projectx/views/login_Page.dart';
import 'package:projectx/views/registration.dart';
import 'package:projectx/views/verify_mail.dart';
import 'package:projectx/views/welcome_Screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _configureLocalNotifications();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseApi().initNotifications();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final user = FirebaseAuth.instance.currentUser;
  late final LocalAuthentication auth;
  late final List<BiometricType> availablebiometrics;
  bool _authenticated = false;
  late bool _supportState;

  @override
  void initState() {
    auth = LocalAuthentication();
    auth.isDeviceSupported().then((bool isDeviceSupported) => setState(() {
          _supportState = isDeviceSupported;
        }));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_supportState) {
      _getAvailableBio();
    }

    return MaterialApp(
      title: 'Project-X',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        appBarTheme: AppBarTheme(color: Colors.teal.shade500),
      ),
      debugShowCheckedModeBanner: false,
      routes: {
        '_Login': (context) => const LoginPage(),
        '_register': (context) => const registrationPage(),
        '_verify': (context) => const VerifyMail(),
        '_homepage': (context) => const HomePage(),
        '/home': (context) => const HomeScreen()
      },
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (user != null) {
              if (_authenticated) {
                return const HomeScreen();
              } else {
                _authenticate();
                return Expanded(
                  child: Container(
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
            } else {
              return const LoginPage();
            }
          } else {
            return const welcomeScreen();
          }
        },
      ),
    );
  }

  Future<void> _getAvailableBio() async {
    try {
      availablebiometrics = await auth.getAvailableBiometrics();
    } catch (e) {
      print(e);
    }
  }

  Future<void> _authenticate() async {
    try {
      _authenticated = await auth.authenticate(
        localizedReason: '     ',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      setState(() {});
      print("Authenticate : $_authenticated");
      if (!_authenticated) {
        _authenticate();
      }
    } on PlatformException catch (e) {
      print(e);
    }
  }
}

void _configureLocalNotifications() {
  var initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  var initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  flutterLocalNotificationsPlugin.initialize(initializationSettings);
}
