import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppConfig {
  const AppConfig({
    required this.firebaseReady,
    this.bootstrapError,
  });

  final bool firebaseReady;
  final Object? bootstrapError;
}

final appConfigProvider = Provider<AppConfig>(
  (ref) => const AppConfig(firebaseReady: false),
);
