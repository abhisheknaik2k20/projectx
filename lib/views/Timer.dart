import 'package:flutter/material.dart';
import 'dart:async';

import 'package:google_fonts/google_fonts.dart';
import 'package:projectx/views/registration.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  _TimerScreenState createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  int _secondsRemaining = 60;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: _secondsRemaining == 0
          ? TextButton(
              child: Text(
                'Verification Failed, Please try Again',
                style: GoogleFonts.ptSans(
                  fontSize: 25,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const registrationPage(),
                    ),
                    (route) => false);
              },
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Time Remaining:  ',
                  style: GoogleFonts.ptSans(
                    color: Colors.amber,
                    fontSize: 25,
                  ),
                ),
                Text(
                  _secondsRemaining.toString(),
                  style: GoogleFonts.ptSans(
                    color: _secondsRemaining < 10 ? Colors.red : Colors.amber,
                    fontSize: _secondsRemaining < 10 ? 37 : 25,
                  ),
                ),
                Text(
                  ' seconds',
                  style: GoogleFonts.ptSans(
                    color: _secondsRemaining < 10 ? Colors.red : Colors.amber,
                    fontSize: _secondsRemaining < 10 ? 30 : 25,
                  ),
                )
              ],
            ),
    );
  }
}
