import 'package:flutter/material.dart';

enum StatusTone { neutral, info, success, warning, danger }

class StatusChip extends StatelessWidget {
  const StatusChip(
    this.label, {
    this.tone = StatusTone.neutral,
    this.icon,
    super.key,
  });

  final String label;
  final StatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      StatusTone.neutral => (const Color(0xFFEEF1F3), const Color(0xFF53636E)),
      StatusTone.info => (const Color(0xFFE4F1F5), const Color(0xFF176B87)),
      StatusTone.success => (const Color(0xFFE3F2EC), const Color(0xFF176B5B)),
      StatusTone.warning => (const Color(0xFFFFF1D6), const Color(0xFF8A5B00)),
      StatusTone.danger => (const Color(0xFFFFE9E7), const Color(0xFFB42318)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: colors.$2),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: colors.$2,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
