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
        return windows;
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
    apiKey: 'AIzaSyBLp6aFrhG-stLv9MSo9PnKH2cuAalE544',
    appId: '1:919301148587:web:83a57aea06033f8b424cee',
    messagingSenderId: '919301148587',
    projectId: 'final66114075',
    authDomain: 'final66114075.firebaseapp.com',
    databaseURL: 'https://final66114075-default-rtdb.firebaseio.com',
    storageBucket: 'final66114075.firebasestorage.app',
    measurementId: 'G-GT3HT9BMW3',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCYayg-04whLmi_8epwUSAgJ6Na1BjfYVw',
    appId: '1:919301148587:android:8830219dedec5eaa424cee',
    messagingSenderId: '919301148587',
    projectId: 'final66114075',
    databaseURL: 'https://final66114075-default-rtdb.firebaseio.com',
    storageBucket: 'final66114075.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCaW0UxQutjeTznaaKxmRjiiHqX8r8Ni4A',
    appId: '1:919301148587:ios:685681c6d5f364b1424cee',
    messagingSenderId: '919301148587',
    projectId: 'final66114075',
    databaseURL: 'https://final66114075-default-rtdb.firebaseio.com',
    storageBucket: 'final66114075.firebasestorage.app',
    iosBundleId: 'com.example.final66114075',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCaW0UxQutjeTznaaKxmRjiiHqX8r8Ni4A',
    appId: '1:919301148587:ios:685681c6d5f364b1424cee',
    messagingSenderId: '919301148587',
    projectId: 'final66114075',
    databaseURL: 'https://final66114075-default-rtdb.firebaseio.com',
    storageBucket: 'final66114075.firebasestorage.app',
    iosBundleId: 'com.example.final66114075',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBLp6aFrhG-stLv9MSo9PnKH2cuAalE544',
    appId: '1:919301148587:web:eefa81fd02eabf8c424cee',
    messagingSenderId: '919301148587',
    projectId: 'final66114075',
    authDomain: 'final66114075.firebaseapp.com',
    databaseURL: 'https://final66114075-default-rtdb.firebaseio.com',
    storageBucket: 'final66114075.firebasestorage.app',
    measurementId: 'G-9H9BW7VLYM',
  );
}
