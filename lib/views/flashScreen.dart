import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:projectx/views/login_Page.dart';

class flashScreen extends StatefulWidget {
  const flashScreen({super.key});

  @override
  State<flashScreen> createState() => _flashScreen();
}

class _flashScreen extends State<flashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(
      const Duration(seconds: 4),
      () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(246, 26, 27, 31),
      body: Center(
        child: Lottie.asset('assets/animation2.json'),
      ),
    );
  }
}
