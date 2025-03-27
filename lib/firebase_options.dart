// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBv3fM5FSN2PKPLCllDIQyzSRzhdiDX9lQ',
    appId: '1:53607531902:web:5bb3f8f58aebf0d8771f2f',
    messagingSenderId: '53607531902',
    projectId: 'projectx-223eb',
    authDomain: 'projectx-223eb.firebaseapp.com',
    storageBucket: 'projectx-223eb.appspot.com',
    measurementId: 'G-DFXQPLC5Z7',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBc3tFWaa-7fuBzGV9z55NeQO5kmRdkI1U',
    appId: '1:53607531902:android:4dd4e6d0906e8d2d771f2f',
    messagingSenderId: '53607531902',
    projectId: 'projectx-223eb',
    storageBucket: 'projectx-223eb.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDWcRnBhOopPnH7r2aFm_3PAzL1eWQ5_Q4',
    appId: '1:53607531902:ios:dbb7bcc80027fe8c771f2f',
    messagingSenderId: '53607531902',
    projectId: 'projectx-223eb',
    storageBucket: 'projectx-223eb.appspot.com',
    iosBundleId: 'com.myprojectapp.projectx',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDWcRnBhOopPnH7r2aFm_3PAzL1eWQ5_Q4',
    appId: '1:53607531902:ios:fa9cfeb42ec0261d771f2f',
    messagingSenderId: '53607531902',
    projectId: 'projectx-223eb',
    storageBucket: 'projectx-223eb.appspot.com',
    iosBundleId: 'com.myprojectapp.projectx.RunnerTests',
  );
}