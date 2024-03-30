import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:projectx/pages/QRScanner/SuccessPage.dart';

class SuccessLoading extends StatefulWidget {
  final String resultid;
  const SuccessLoading({super.key, required this.resultid});

  @override
  State<SuccessLoading> createState() => _SuccessLoadingState();
}

class _SuccessLoadingState extends State<SuccessLoading> {
  @override
  void initState() {
    super.initState();
    Timer(
      const Duration(seconds: 5),
      () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => Success(
                    resultid: widget.resultid,
                  )),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade400,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/fetching.json'),
            Text(
              'Fetching Details.....',
              style: GoogleFonts.anton(
                fontSize: 40,
                color: Colors.grey.shade800,
              ),
            )
          ],
        ),
      ),
    );
  }
}
