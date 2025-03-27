// ignore_for_file: non_constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:projectx/pages/API_Call_Screen/Screen1.dart';
import 'package:vibration/vibration.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({
    super.key,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  void Vibrate() {
    Vibration.vibrate(pattern: [100, 200, 300, 400], repeat: 1);
  }

  FirebaseFirestore db = FirebaseFirestore.instance;
  String UID = FirebaseAuth.instance.currentUser!.uid;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade400,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.circle,
                      size: 260,
                      color: Color.fromARGB(255, 5, 1, 72),
                    ),
                    Icon(Icons.circle, size: 240, color: Colors.teal.shade400),
                    const Icon(
                      Icons.account_circle,
                      size: 220,
                      color: Color.fromARGB(255, 5, 1, 72),
                    ),
                  ],
                ),
                StreamBuilder(
                    stream: db
                        .collection('users')
                        .doc(UID)
                        .collection('call_info')
                        .doc(UID)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.data?.data() != null) {
                        Vibrate();
                      } else {
                        Vibration.cancel();
                      }
                      return Text(
                        snapshot.data?.data()?['caller_Name'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'PT Sans Caption',
                        ),
                      );
                    }),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(70),
                  topRight: Radius.circular(70),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.call,
                        color: Colors.white,
                        size: 180,
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.all(
                            Radius.circular(60),
                          ),
                        ),
                        child: IconButton(
                          onPressed: () {
                            Vibration.cancel();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const MyHomePage(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.call,
                            color: Colors.white,
                            size: 60,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.call_end_rounded,
                        color: Colors.red,
                        size: 180,
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.all(
                            Radius.circular(60),
                          ),
                        ),
                        child: IconButton(
                          onPressed: () async {
                            Vibration.cancel();
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser!.uid)
                                .update({'isCall': false});
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser!.uid)
                                .collection('call_info')
                                .doc(FirebaseAuth.instance.currentUser!.uid)
                                .delete();
                          },
                          icon: const Icon(
                            Icons.call_end_rounded,
                            color: Colors.white,
                            size: 60,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
