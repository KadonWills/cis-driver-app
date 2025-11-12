// NOTE: This file needs to be generated using FlutterFire CLI
// Run: flutterfire configure
// This will generate the proper firebase_options.dart file

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAqPObVvWr4EL6WwZHmar-ZLQDCmnC0kOM',
    appId: '1:523486500169:android:cd65a77e190b8d9be23698',
    messagingSenderId: '523486500169',
    projectId: 'concept-illustrated-mvp',
    databaseURL: 'https://concept-illustrated-mvp-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'concept-illustrated-mvp.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCFKlo29ilJBDzd1kl8oZEOGtKLZmzxhuk',
    appId: '1:523486500169:ios:4cdbf48dcaed60dbe23698',
    messagingSenderId: '523486500169',
    projectId: 'concept-illustrated-mvp',
    databaseURL: 'https://concept-illustrated-mvp-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'concept-illustrated-mvp.firebasestorage.app',
    iosBundleId: 'com.dinovix.cisDriverApp',
  );

}
