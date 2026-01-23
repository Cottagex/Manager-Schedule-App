// File generated manually for Firebase configuration.
// To regenerate, run `flutterfire configure`.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyDx1Xy_D4tA6IGF0npFPpnwzeOkh4rrnxo',
    appId: '1:991523306618:web:cd1492edc5a7bb48d58fc3',
    messagingSenderId: '991523306618',
    projectId: 'schedulehq-cf87f',
    authDomain: 'schedulehq-cf87f.firebaseapp.com',
    storageBucket: 'schedulehq-cf87f.firebasestorage.app',
  );

  // Windows uses the web configuration
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDx1Xy_D4tA6IGF0npFPpnwzeOkh4rrnxo',
    appId: '1:991523306618:web:cd1492edc5a7bb48d58fc3',
    messagingSenderId: '991523306618',
    projectId: 'schedulehq-cf87f',
    authDomain: 'schedulehq-cf87f.firebaseapp.com',
    storageBucket: 'schedulehq-cf87f.firebasestorage.app',
  );

  // Android configuration - will be updated when you register an Android app
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDx1Xy_D4tA6IGF0npFPpnwzeOkh4rrnxo',
    appId: '1:991523306618:web:cd1492edc5a7bb48d58fc3', // Replace with Android appId
    messagingSenderId: '991523306618',
    projectId: 'schedulehq-cf87f',
    storageBucket: 'schedulehq-cf87f.firebasestorage.app',
  );
}
