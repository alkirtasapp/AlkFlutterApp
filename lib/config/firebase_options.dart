import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase project `app-tracking-4a895`.
///
/// Android values come from android/app/google-services.json.
/// iOS values come from the GoogleService-Info.plist downloaded from the
/// Firebase console (iOS app `com.alkirtas.alkirtas`). Until they are filled
/// in, [currentPlatform] returns null on iOS and push stays disabled there.
class DefaultFirebaseOptions {
  static FirebaseOptions? get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return null;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC4SAK_0VrCxV9lAXDShgUu1cR-gn8F3Zo',
    appId: '1:807654268134:android:e8f2385f4ae1245c2e6f27',
    messagingSenderId: '807654268134',
    projectId: 'app-tracking-4a895',
    storageBucket: 'app-tracking-4a895.firebasestorage.app',
  );

  // TODO: fill from GoogleService-Info.plist (API_KEY, GOOGLE_APP_ID).
  static const FirebaseOptions? ios = null;
}
