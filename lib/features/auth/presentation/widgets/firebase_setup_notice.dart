import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';

class FirebaseSetupNotice extends ConsumerWidget {
  const FirebaseSetupNotice({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(appConfigProvider).firebaseReady) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7C46A)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.settings_outlined, size: 20, color: Color(0xFF8A5B00)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Firebase configuration is required before cloud sign-in can be used.',
              style: TextStyle(color: Color(0xFF6B4A05), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
