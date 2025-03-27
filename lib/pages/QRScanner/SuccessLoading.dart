import 'dart:async';
import 'package:flutter/material.dart';
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
            Icon(
              Icons.cloud_download,
              size: 100,
              color: Colors.grey.shade800,
            ),
            const SizedBox(height: 20),
            Text(
              'Fetching Details.....',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w400,
                color: Colors.grey.shade800,
              ),
            )
          ],
        ),
      ),
    );
  }
}
