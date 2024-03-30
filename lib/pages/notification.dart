import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class NotificationP extends StatelessWidget {
  const NotificationP({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/noti.json'),
          Text(
            "Comming Soon...",
            style: GoogleFonts.anton(fontSize: 40, color: Colors.teal.shade800),
          )
        ],
      )),
    );
  }
}
