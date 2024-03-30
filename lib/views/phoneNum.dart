import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:pinput/pinput.dart';
import 'package:projectx/views/Timer.dart';

class phoneNumVerfication extends StatefulWidget {
  final String firstname;
  final String lastname;
  final String username;
  final String email;
  final String phonenumber;
  final String password;
  const phoneNumVerfication(
      {required this.firstname,
      required this.lastname,
      required this.username,
      required this.email,
      required this.phonenumber,
      required this.password,
      super.key});

  @override
  State<phoneNumVerfication> createState() => phoneNumVerficationState();
}

class phoneNumVerficationState extends State<phoneNumVerfication> {
  final FirebaseAuth auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    AcceptPhoneNumber? acceptPhoneNumber =
        ModalRoute.of(context)?.settings.arguments as AcceptPhoneNumber?;
    return Scaffold(
        backgroundColor: const Color.fromARGB(246, 26, 27, 31),
        body: SingleChildScrollView(
          child: SingleChildScrollView(
            child: Form(
              child: Center(
                  child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 200),
                    child: Container(child: Lottie.asset('assets/OTP2.json')),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      "Please Enter The 6-Digit OTP",
                      style: GoogleFonts.ptSansCaption(
                          fontSize: 25, color: Colors.teal.shade500),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 50),
                    child: Container(
                        child: Pinput(
                      length: 6,
                      defaultPinTheme: PinTheme(
                          height: 35,
                          width: 35,
                          textStyle: const TextStyle(
                              fontSize: 25, color: Colors.white),
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.teal.shade500))),
                      onCompleted: (pin) async {
                        try {
                          PhoneAuthCredential credential =
                              PhoneAuthProvider.credential(
                                  verificationId:
                                      acceptPhoneNumber!.verificationID,
                                  smsCode: pin);
                          await auth.signInWithCredential(credential);

                          Navigator.of(context).pushNamedAndRemoveUntil(
                              '_homepage', (route) => false);
                          _showSnackbar(context);
                          CollectionReference users =
                              FirebaseFirestore.instance.collection('users');
                          String? fCMToken =
                              await FirebaseMessaging.instance.getToken();
                          await users
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .set({
                            'username': widget.username,
                            'phone': widget.phonenumber,
                            'email': widget.email,
                            'name': '${widget.firstname} ${widget.lastname}',
                            'uid': FirebaseAuth.instance.currentUser!.uid
                                .toString(),
                            'status': 'Offline',
                            'fcmToken': fCMToken,
                          }).then((value) => print('User Added'));
                        } on FirebaseAuthException catch (e) {
                          setState(() {});
                          _showErrorSnackbar(e.code, context);
                        }
                      },
                    )),
                  ),
                  const TimerScreen(),
                ],
              )),
            ),
          ),
        ));
  }

  void _showSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(height: 50, child: Lottie.asset('assets/success.json')),
            const SizedBox(width: 8.0),
            const Text(
              'Logging in..........',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackbar(String message, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(height: 95, child: Lottie.asset('assets/error2.json')),
            const SizedBox(width: 8.0),
            Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
          ],
        ),
        backgroundColor: Colors.red,
      ),
    );
  }
}

class AcceptPhoneNumber {
  final String phonenumber;
  final String verificationID;
  AcceptPhoneNumber(this.phonenumber, this.verificationID);
}
