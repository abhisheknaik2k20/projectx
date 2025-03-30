import 'package:SwiftTalk/CONTROLLER/User_Repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

Future<void> emailpassLogin(
    String email, String password, BuildContext context) async {
  showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()));
  try {
    await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);

    final userRepository = UserRepository();
    await userRepository.updateFcmToken(FirebaseAuth.instance.currentUser!.uid);
  } on FirebaseAuthException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.code),
        backgroundColor: Colors.red,
      ));
    }
  }
  if (context.mounted) {
    Navigator.of(context).pop();
  }
}

Future<void> emailpassSignup(
    String email, String password, String phone, BuildContext context) async {
  showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()));
  try {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final userRepository = UserRepository();
    await userRepository.saveUser(FirebaseAuth.instance.currentUser);

    if (context.mounted) {
      Navigator.of(context).pop();
    }
  } on FirebaseAuthException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.code),
        backgroundColor: Colors.red,
      ));
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('An error occurred, please try again.'),
      backgroundColor: Colors.red,
    ));
  }
}

Future<void> implementGoogleSignIn(BuildContext context) async {
  try {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return;

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);

    final UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    final User? user = userCredential.user;
    if (user == null) return;

    final userRepository = UserRepository();
    await userRepository.saveUser(user);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in failed: ${e.toString()}')));
    }
  }
}
