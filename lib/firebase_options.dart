// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCoEu8ia4Pr0jQuE-K47ehoJhqheDTIpyg',
    appId: '1:921125601957:web:195f7904ee21ed583f034c',
    messagingSenderId: '921125601957',
    projectId: 'tango-calendar-app',
    authDomain: 'tango-calendar-app.firebaseapp.com',
    storageBucket: 'tango-calendar-app.appspot.com',
    measurementId: 'G-422757VVG6',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCoEu8ia4Pr0jQuE-K47ehoJhqheDTIpyg',
    appId: '1:921125601957:android:c744660b2ab449a53f034c',
    messagingSenderId: '921125601957',
    projectId: 'tango-calendar-app',
    storageBucket: 'tango-calendar-app.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBzlspUDcLSQdNPJdj5GEvtCZQoGv5G7t0',
    appId: '1:921125601957:ios:8b8b438d5d89baa93f034c',
    messagingSenderId: '921125601957',
    projectId: 'tango-calendar-app',
    storageBucket: 'tango-calendar-app.appspot.com',
    iosClientId: '921125601957-5h5rtcr5va3jhv4mv87dv2q9tc7sdf9d.apps.googleusercontent.com',
    iosBundleId: 'com.tangocalendar.tangoCalendar',
  );
}
