// QuickFix app registrations in aclon-franz, retrieved with Firebase CLI.
import "package:firebase_core/firebase_core.dart";
import "package:flutter/foundation.dart";

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return android;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return ios;
    }
    throw UnsupportedError("QuickFix supports Android, iOS, and web.");
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyAtbbvoD1tWogEdIZuMii4CqVivhSQjXp8",
    appId: "1:976197366702:web:37130afaa0ab6f791bce3f",
    messagingSenderId: "976197366702",
    projectId: "aclon-franz",
    storageBucket: "aclon-franz.firebasestorage.app",
    authDomain: "aclon-franz.firebaseapp.com",
  );
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyAI6BcJpPkd_XKV12ibOcJsHo8eIurKEb0",
    appId: "1:976197366702:android:82110f9e39c4da651bce3f",
    messagingSenderId: "976197366702",
    projectId: "aclon-franz",
    storageBucket: "aclon-franz.firebasestorage.app",
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyAOsXhb1kArBDrRxqmAgVskN3FcIPDDyzU",
    appId: "1:976197366702:ios:32e6fe61375314ac1bce3f",
    messagingSenderId: "976197366702",
    projectId: "aclon-franz",
    storageBucket: "aclon-franz.firebasestorage.app",
    iosBundleId: "com.aclon.quickfix",
  );
}
