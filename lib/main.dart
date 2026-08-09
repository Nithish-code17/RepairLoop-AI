import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/config/runtime_firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var firebaseReady = false;
  Object? bootstrapError;
  try {
    if (RuntimeFirebaseOptions.hasExplicitOptions) {
      await Firebase.initializeApp(options: RuntimeFirebaseOptions.currentPlatform);
    } else {
      await Firebase.initializeApp();
    }
    const recaptchaSiteKey = String.fromEnvironment('RECAPTCHA_V3_SITE_KEY');
    if (kIsWeb && recaptchaSiteKey.isEmpty) {
      throw StateError(
        'RECAPTCHA_V3_SITE_KEY is required for Firebase App Check on web.',
      );
    }
    await FirebaseAppCheck.instance.activate(
      providerWeb:
          kIsWeb ? ReCaptchaV3Provider(recaptchaSiteKey) : null,
      providerAndroid:
          kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      providerApple: kDebugMode
          ? AppleProvider.debug
          : AppleProvider.appAttestWithDeviceCheckFallback,
    );
    firebaseReady = true;
  } catch (error) {
    bootstrapError = error;
  }

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(
          AppConfig(
            firebaseReady: firebaseReady,
            bootstrapError: bootstrapError,
          ),
        ),
      ],
      child: const RepairLoopApp(),
    ),
  );
}
