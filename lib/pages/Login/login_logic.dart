// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

Future<void> emailpassLogin(String email, String password, BuildContext context,
    String selectedUserType) async {
  showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()));
  try {
    await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .set({'fcmToken': FirebaseMessaging.instance.getToken()},
            SetOptions(merge: true));
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
  String email,
  String password,
  String phone,
  BuildContext context,
  String selectedUserType,
) async {
  showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()));
  try {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    User? user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance.collection('users').doc(user?.uid).set(
      {
        'email': email,
        'name': user?.displayName ?? '',
        'uid': user?.uid,
        'photoURL': user?.photoURL ?? '',
        'status': 'Online',
        'createdAt': FieldValue.serverTimestamp(),
        'username': user?.displayName,
        'isCall': false,
        'fcmToken': FirebaseMessaging.instance.getToken()
      },
    );
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

Future<void> implementGoogleSignIn(
    BuildContext context, String selectedUserType) async {
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
    final token = await FirebaseMessaging.instance.getToken() ?? 'N/A';
    if (user == null) return;
    final String? email = user.providerData.isNotEmpty
        ? user.providerData.first.email
        : user.email;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'email': email ?? '',
      'name': user.displayName ?? '',
      'uid': user.uid,
      'photoURL': user.photoURL ?? '',
      'status': 'Online',
      'createdAt': FieldValue.serverTimestamp(),
      'username': user.displayName,
      'isCall': false,
      'fcmToken': token
    }, SetOptions(merge: true));
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in failed: ${e.toString()}')));
    }
  }
}
