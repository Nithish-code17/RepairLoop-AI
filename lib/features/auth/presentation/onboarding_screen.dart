import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/content_frame.dart';
import 'widgets/firebase_setup_notice.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: ContentFrame(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;
                final introduction = Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _ProductBrand(),
                    const SizedBox(height: 52),
                    Text(
                      'A trusted service record for every device.',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontSize: wide ? 44 : 34,
                            height: 1.12,
                          ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Register electronic products, preserve repair history, '
                      'and get safe preliminary troubleshooting guidance before '
                      'a technician begins work.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF60717D),
                          ),
                    ),
                    const SizedBox(height: 30),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton(
                          onPressed: () => context.go('/login'),
                          child: const Text('Sign in'),
                        ),
                        OutlinedButton(
                          onPressed: () => context.go('/register'),
                          child: const Text('Create account'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const FirebaseSetupNotice(compact: true),
                  ],
                );

                final workflow = const _WorkflowPanel();
                return wide
                    ? Row(
                        children: [
                          Expanded(child: introduction),
                          const SizedBox(width: 64),
                          Expanded(child: workflow),
                        ],
                      )
                    : ListView(
                        children: [
                          const SizedBox(height: 28),
                          introduction,
                          const SizedBox(height: 40),
                          workflow,
                          const SizedBox(height: 24),
                        ],
                      );
              },
            ),
          ),
        ),
      );
}

class _ProductBrand extends StatelessWidget {
  const _ProductBrand();

  @override
  Widget build(BuildContext context) => const Row(
        children: [
          Icon(Icons.build_circle_outlined, color: Color(0xFF142B3A), size: 30),
          SizedBox(width: 10),
          Text(
            'RepairLoop',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          SizedBox(width: 8),
          Text('AI', style: TextStyle(color: Color(0xFF60717D))),
        ],
      );
}

class _WorkflowPanel extends StatelessWidget {
  const _WorkflowPanel();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6F8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDCE2E7)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _WorkflowRow(
              icon: Icons.qr_code_2,
              title: 'Digital product passport',
              text: 'One verified record for identity, warranty and components.',
            ),
            Divider(height: 32),
            _WorkflowRow(
              icon: Icons.fact_check_outlined,
              title: 'Guided fault assessment',
              text: 'Symptoms, images and product history analyzed together.',
            ),
            Divider(height: 32),
            _WorkflowRow(
              icon: Icons.handyman_outlined,
              title: 'Documented repair work',
              text: 'Technician actions and replacement parts stay traceable.',
            ),
          ],
        ),
      );
}

class _WorkflowRow extends StatelessWidget {
  const _WorkflowRow({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDCE2E7)),
            ),
            child: Icon(icon, color: const Color(0xFF176B87)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(text, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      );
}
