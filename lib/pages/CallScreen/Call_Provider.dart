import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CallStatusProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isCallActive = false;

  bool get isCallActive => _isCallActive;
  Stream<DocumentSnapshot>? _callStatusStream;
  StreamSubscription<DocumentSnapshot>? _subscription;

  CallStatusProvider() {
    _initCallStatusStream();
  }

  void _initCallStatusStream() {
    if (_auth.currentUser != null) {
      _callStatusStream =
          _db.collection('users').doc(_auth.currentUser!.uid).snapshots();
      _subscription = _callStatusStream!.listen((snapshot) {
        final newCallStatus = snapshot.get('isCall') ?? false;
        if (newCallStatus != _isCallActive) {
          _isCallActive = newCallStatus;
          notifyListeners();
        }
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
