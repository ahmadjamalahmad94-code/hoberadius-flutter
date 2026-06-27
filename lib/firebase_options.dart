// Firebase options for the HobeRadius app — ANDROID ONLY (iOS deferred).
//
// Hand-authored (equivalent to `flutterfire configure` output) from the
// Firebase project "hoberadius", Android app `com.hoberadius.app`. Only the
// Android platform is configured; iOS/macOS/web/Windows/Linux throw so a
// mis-targeted call fails loudly instead of silently using wrong creds.
// All runtime callers gate on PlatformCapabilities.isMobile (≈ Android here).
//
// These are CLIENT identifiers (package-restricted), safe to commit. The
// Firebase ADMIN SDK private key is server-only and must NEVER live here.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'FCM is not configured for web — Android only for now.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'iOS push is deferred — add GoogleService-Info.plist and an iOS '
          'FirebaseOptions entry to enable it.',
        );
      default:
        throw UnsupportedError(
          'FCM is not configured for $defaultTargetPlatform — Android only.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA73rNU5ypuxTKzoQ9PqS9EEvIeJBAVUt0',
    appId: '1:358020404999:android:82102636924bea5a4297a2',
    messagingSenderId: '358020404999',
    projectId: 'hoberadius',
    storageBucket: 'hoberadius.firebasestorage.app',
  );
}
