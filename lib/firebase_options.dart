// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
    apiKey: 'AIzaSyBC7SwkXACJGgJwckoq_kKfu4nM1ihuJwg',
    appId: '1:547065230418:android:ef3468a8165b0b53f69b8b',
    messagingSenderId: '547065230418',
    projectId: 'huapoaiapp',
    storageBucket: 'huapoaiapp.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD-j6GUQJ2JG0vkNosH6a5RYNjBVl1e4dE',
    appId: '1:547065230418:ios:5c2234030ab36800f69b8b',
    messagingSenderId: '547065230418',
    projectId: 'huapoaiapp',
    storageBucket: 'huapoaiapp.firebasestorage.app',
    androidClientId: '547065230418-2mjuamu27crmeese9jbucphv71emo78j.apps.googleusercontent.com',
    iosClientId: '547065230418-f9lbi4ut08e0rmv3mf085v5mdsdb4dr6.apps.googleusercontent.com',
    iosBundleId: 'com.huapoai.huapoai',
  );

}