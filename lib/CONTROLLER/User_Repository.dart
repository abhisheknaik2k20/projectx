import 'package:SwiftTalk/models/User.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class UserRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');

  Future<void> saveUser(User? firebaseUser) async {
    if (firebaseUser == null) return;
    String fcmToken = await _messaging.getToken() ?? '';
    final userData = UserModel(
        email: firebaseUser.email ?? '',
        name: firebaseUser.displayName ?? '',
        uid: firebaseUser.uid,
        photoURL: firebaseUser.photoURL ?? '',
        username: firebaseUser.displayName ?? '',
        fcmToken: fcmToken);
    await _usersCollection
        .doc(firebaseUser.uid)
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

  Future<List<UserModel>> getAllUsers() async {
    try {
      QuerySnapshot querySnapshot = await _usersCollection.get();
      return querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  Stream<UserModel?> streamUserData(String userId) {
    return _usersCollection.doc(userId).snapshots().map((doc) => doc.exists
        ? UserModel.fromMap(doc.data() as Map<String, dynamic>)
        : null);
  }
}
