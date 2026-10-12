// Firebase configuration for the existing Android app.
// Values are taken from android/app/google-services.json.
// Run flutterfire configure again when adding another platform.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return android;
    }
    throw UnsupportedError(
      'Firebase hiện được cấu hình cho Android. '
      'Hãy chạy ứng dụng trên điện thoại hoặc máy ảo Android.',
    );
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCfMZi7Qdm5bwIYFukoKtWc_DNqupG_Hxc',
    appId: '1:449028567630:android:5fe33c8d6dccab8091891f',
    messagingSenderId: '449028567630',
    projectId: 'music-app-th6-719a9',
    storageBucket: 'music-app-th6-719a9.firebasestorage.app',
  );
}
