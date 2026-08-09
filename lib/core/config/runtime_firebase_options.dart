import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Public Firebase client identifiers for the RepairLoop AI project.
///
/// Firebase client configuration is intentionally bundled with client apps and
/// is not the private multimodal AI credential. The AI provider key remains a
/// Cloud Functions secret. CI or another Firebase environment can override any
/// value with the matching `--dart-define`.
abstract final class RuntimeFirebaseOptions {
  static const _apiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'AIzaSyB-G_y82OQocR9YE-ahzyIxTmXlFJJMY5s',
  );
  static const _projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'repairloop-ai',
  );
  static const _messagingSenderId =
      String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '508246584049',
  );
  static const _storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: 'repairloop-ai.firebasestorage.app',
  );
  static const _authDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
    defaultValue: 'repairloop-ai.firebaseapp.com',
  );
  static const _androidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
    defaultValue: '1:508246584049:android:d155dff5f209442ea6d750',
  );
  static const _iosAppId = String.fromEnvironment(
    'FIREBASE_IOS_APP_ID',
    defaultValue: '1:508246584049:ios:a0cb4458c427bbaea6d750',
  );
  static const _webAppId = String.fromEnvironment(
    'FIREBASE_WEB_APP_ID',
    defaultValue: '1:508246584049:web:c05e2e7abcce5b9da6d750',
  );
  static const _iosBundleId = String.fromEnvironment(
    'FIREBASE_IOS_BUNDLE_ID',
    defaultValue: 'com.nithishsarwin.repairloopai',
  );

  static bool get hasExplicitOptions =>
      _apiKey.isNotEmpty &&
      _projectId.isNotEmpty &&
      _messagingSenderId.isNotEmpty &&
      _appIdForCurrentPlatform.isNotEmpty;

  static String get _appIdForCurrentPlatform {
    if (kIsWeb) return _webAppId;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => _androidAppId,
      TargetPlatform.iOS || TargetPlatform.macOS => _iosAppId,
      _ => _webAppId,
    };
  }

  static FirebaseOptions get currentPlatform => FirebaseOptions(
        apiKey: _apiKey,
        appId: _appIdForCurrentPlatform,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        storageBucket: _storageBucket.isEmpty ? null : _storageBucket,
        authDomain: _authDomain.isEmpty ? null : _authDomain,
        iosBundleId: _iosBundleId.isEmpty ? null : _iosBundleId,
      );
}
