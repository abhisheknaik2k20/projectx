import 'package:android_intent_plus/android_intent.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:projectx/pages/HomeScreen.dart';
import 'dart:io' show Platform;

class VerifyMail extends StatelessWidget {
  const VerifyMail({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          final user = FirebaseAuth.instance.currentUser;
          if (snapshot.hasData && user != null && user.emailVerified) {
            return const HomeScreen();
          } else {
            return Scaffold(
                backgroundColor: const Color.fromARGB(246, 26, 27, 31),
                body: SafeArea(
                  child: SingleChildScrollView(
                      child: Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 150),
                            child: Icon(
                              Icons.email,
                              size: 100,
                              color: Colors.teal.shade500,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 15, left: 60, right: 40),
                            child: Text(
                                'Kindly review your default email application for the user verification email. ',
                                style: TextStyle(
                                    color: Colors.teal.shade500, fontSize: 20)),
                          ),
                          Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: ElevatedButton(
                                  style: ButtonStyle(
                                    overlayColor: MaterialStateProperty
                                        .resolveWith<Color>(
                                      (Set<MaterialState> states) {
                                        if (states
                                            .contains(MaterialState.pressed)) {
                                          return Colors.grey.withOpacity(0.8);
                                        }
                                        return Colors.transparent;
                                      },
                                    ),
                                    backgroundColor: MaterialStateProperty.all(
                                        Colors.teal.shade500),
                                  ),
                                  onPressed: () async {
                                    await FirebaseAuth.instance.currentUser
                                        ?.reload();
                                    if (Platform.isAndroid) {
                                      const AndroidIntent intent =
                                          AndroidIntent(
                                        action: 'android.intent.action.MAIN',
                                        category:
                                            'android.intent.category.APP_EMAIL',
                                      );
                                      intent.launch().catchError((e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              e.code,
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      });
                                    }
                                  },
                                  child: const Text("Go to E-Mail app",
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)))),
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: TextButton(
                              style: ButtonStyle(
                                overlayColor:
                                    MaterialStateProperty.resolveWith<Color>(
                                  (Set<MaterialState> states) {
                                    if (states
                                        .contains(MaterialState.pressed)) {
                                      return Colors.grey.withOpacity(0.8);
                                    }
                                    return Colors.transparent;
                                  },
                                ),
                              ),
                              onPressed: () async {
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                    '_Login', (route) => false);
                              },
                              child: const Text(
                                "Log-in Page",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          )
                        ]),
                  )),
                ));
          }
        });
  }
}
