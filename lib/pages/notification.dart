import 'package:flutter/material.dart';

class NotificationP extends StatelessWidget {
  const NotificationP({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications,
            size: 100,
            color: Colors.teal.shade800,
          ),
          Text(
            "Coming Soon...",
            style: TextStyle(
              fontSize: 40,
              color: Colors.teal.shade800,
              fontFamily: 'Anton',
            ),
          )
        ],
      )),
    );
  }
}
