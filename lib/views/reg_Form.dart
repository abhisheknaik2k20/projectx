import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

class SignupController extends GetxController {
  static SignupController get instace => Get.find();
  late final emailcontroller = TextEditingController();
  late final passcontroller = TextEditingController();
  late final firstnamecontroller = TextEditingController();
  late final lastnamecontroller = TextEditingController();
  late final usernamecontroller = TextEditingController();
  late final phonenumbercontroller = TextEditingController();
  late final dateofbirthcontrol = TextEditingController();
  GlobalKey<FormState> signupFormKey = GlobalKey<FormState>();

  Future<void> signup(BuildContext context) async {
    try {
      CollectionReference users =
          FirebaseFirestore.instance.collection('users');

      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailcontroller.text,
        password: passcontroller.text,
      );
      showSnackbarWithProgress(context);

      String uid = userCredential.user!.uid;
      String? fCMToken = await FirebaseMessaging.instance.getToken();
      await users.doc(uid).set({
        'username': usernamecontroller.text,
        'phone': phonenumbercontroller.text,
        'password': passcontroller.text,
        'email': emailcontroller.text,
        'name': '${firstnamecontroller.text} ${lastnamecontroller.text}',
        'uid': uid,
        'status': 'Offline',
        'fcmToken': fCMToken,
        'dob': dateofbirthcontrol.text
      }).then(
        (value) => print('User Added'),
      );

      await userCredential.user!.updateDisplayName(usernamecontroller.text);
      await userCredential.user!.updateEmail(emailcontroller.text);
      await userCredential.user!.updatePassword(passcontroller.text);

      if (!userCredential.user!.emailVerified) {
        await userCredential.user!.sendEmailVerification();
      }
      clearText(2);
    } on FirebaseAuthException catch (e) {
      _showErrorSnackbar(e.code, context);
      clearText(1);
      Navigator.of(context)
          .pushNamedAndRemoveUntil('_register', (route) => false);
    }
  }

  void clearText(int flag) {
    switch (flag) {
      case 1:
        emailcontroller.clear();
        break;
      case 2:
        emailcontroller.clear();
        firstnamecontroller.clear();
        lastnamecontroller.clear();
        usernamecontroller.clear();
        phonenumbercontroller.clear();
        passcontroller.clear();
    }
  }

  void _showErrorSnackbar(String message, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0.0,
        content: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.all(
              Radius.circular(20),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                FontAwesomeIcons.warning,
                color: Colors.amber,
              ),
              const SizedBox(
                width: 20,
              ),
              Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
      ),
    );
  }

  Future<void> showSnackbarWithProgress(BuildContext context) async {
    const snackBar = SnackBar(
      content: Row(
        children: [
          Icon(Icons.email, color: Colors.blue, size: 30),
          SizedBox(width: 16.0),
          Text("Sending Verification Mail..........."),
        ],
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    await Future.delayed(const Duration(seconds: 4));
  }
}
