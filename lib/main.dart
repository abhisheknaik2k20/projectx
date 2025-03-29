import 'package:SwiftTalk/pages/CallScreen/Call_Provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:SwiftTalk/firebase_options.dart';
import 'package:SwiftTalk/pages/BlackScreen.dart';
import 'package:SwiftTalk/pages/Login/login_screen.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.android,
  );
  //FirebaseApi().initNotifications();
  runApp(
    ChangeNotifierProvider(
      create: (context) => CallStatusProvider(),
      child: MyApp(),
    ),
  );
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
      title: 'SwiftTalk',
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
