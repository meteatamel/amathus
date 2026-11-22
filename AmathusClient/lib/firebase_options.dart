import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Web Push (VAPID) public key from Firebase Console -> Project Settings -> Cloud Messaging.
const String kWebPushVapidKey =
    'BDnBjV1EbwjSDrsQHTiNzebzO6l61KbLU7jPAuR99iHp-hNYdLhkc8-xY6WjOv_jX8VYLljSvstCXdAOsW7Fn78';

/// Firebase configuration for Amathus (project: events-atamel).
///
/// Web is configured directly below. When building native Android/iOS store
/// releases, drop in `google-services.json` (Android) and
/// `GoogleService-Info.plist` (iOS) or run `flutterfire configure` —
/// `Firebase.initializeApp()` will pick them up automatically.
class DefaultFirebaseOptions {
  static FirebaseOptions? get currentPlatformOrNull {
    if (kIsWeb) {
      return web;
    }
    return null;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD_V4Joz-pXtBSU9LQ8srBc8BXtdfPYzys',
    appId: '1:1086570528700:web:8c30efa9f04507bf9675b9',
    messagingSenderId: '1086570528700',
    projectId: 'events-atamel',
    authDomain: 'events-atamel.firebaseapp.com',
    storageBucket: 'events-atamel.firebasestorage.app',
    measurementId: 'G-6KGJ0WKS78',
  );
}
