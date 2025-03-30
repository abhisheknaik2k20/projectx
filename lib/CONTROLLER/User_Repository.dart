import 'package:SwiftTalk/MODELS/User.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class UserRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');

  Future<void> saveUser(String email) async {
    String fcmToken = await _messaging.getToken() ?? '';
    final userData = UserModel(
        email: email,
        name: _auth.currentUser?.displayName ?? '',
        uid: _auth.currentUser?.uid ?? '',
        photoURL: _auth.currentUser?.photoURL ?? '',
        username: _auth.currentUser?.displayName ?? '',
        fcmToken: fcmToken);
    await _usersCollection
        .doc(_auth.currentUser?.uid)
        .set(userData.toMap(), SetOptions(merge: true));
  }

  Future<UserModel?> getUserById(String userId) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  Future<UserModel?> getCurrentUser() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      return getUserById(currentUser.uid);
    }
    return null;
  }

  Future<void> updateUserStatus(String userId, String status) async {
    await _usersCollection.doc(userId).update({'status': status});
  }

  Future<void> updateFcmToken(String userId) async {
    String fcmToken = await _messaging.getToken() ?? '';
    await _usersCollection.doc(userId).update({'fcmToken': fcmToken});
  }

  Future<void> updateCallStatus(String userId, bool isCall) async {
    await _usersCollection.doc(userId).update({'isCall': isCall});
  }

  Stream<List<UserModel>> getAllUsers() {
    return _usersCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .where((user) => user.uid != _auth.currentUser?.uid)
          .toList();
    });
  }

  Stream<UserModel?> streamUserData(String userId) {
    return _usersCollection.doc(userId).snapshots().map((doc) => doc.exists
        ? UserModel.fromMap(doc.data() as Map<String, dynamic>)
        : null);
  }
}
