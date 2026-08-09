import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers/app_providers.dart';

class LaunchScreen extends ConsumerStatefulWidget {
  const LaunchScreen({super.key});

  @override
  ConsumerState<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends ConsumerState<LaunchScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_resolveSession);
  }

  Future<void> _resolveSession() async {
    final config = ref.read(appConfigProvider);
    if (!config.firebaseReady) {
      if (mounted) context.go('/welcome');
      return;
    }
    final user = await ref.read(authUserProvider.future);
    if (!mounted) return;
    context.go(user == null ? '/welcome' : '/app/home');
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BrandMark(size: 58),
              SizedBox(height: 18),
              Text(
                'RepairLoop',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ],
          ),
        ),
      );
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF142B3A),
          borderRadius: BorderRadius.circular(size * .2),
        ),
        child: Icon(
          Icons.build_circle_outlined,
          color: Colors.white,
          size: size * .56,
        ),
      );
}
