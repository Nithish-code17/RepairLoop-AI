import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/content_frame.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/status_chip.dart';
import '../domain/repair_case.dart';

class RepairsScreen extends ConsumerWidget {
  const RepairsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ContentFrame(
        child: Column(
          children: [
            const PageHeader(
              title: 'Repair cases',
              description: 'Track requests from submission through completion.',
            ),
            const SizedBox(height: 22),
            Expanded(
              child: AsyncValueView(
                value: ref.watch(repairsProvider),
                data: (repairs) => repairs.isEmpty
                    ? const _EmptyRepairs()
                    : ListView.separated(
                        itemCount: repairs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) =>
                            _RepairCard(repair: repairs[index]),
                      ),
              ),
            ),
          ],
        ),
      );
}

class _RepairCard extends StatelessWidget {
  const _RepairCard({required this.repair});

  final RepairCase repair;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFE4F1F5),
            child: Icon(Icons.build_outlined, color: Color(0xFF176B87)),
          ),
          title: Text(
            repair.issueSummary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('Case ${repair.id}'),
          ),
          trailing: StatusChip(
            repair.status.label.toUpperCase(),
            tone: repair.status == RepairStatus.completed
                ? StatusTone.success
                : StatusTone.warning,
          ),
          onTap: () => context.push('/repairs/${repair.id}'),
        ),
      );
}

class _EmptyRepairs extends StatelessWidget {
  const _EmptyRepairs();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.build_outlined, size: 42, color: Color(0xFF60717D)),
            const SizedBox(height: 12),
            Text('No repair cases yet', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Repair requests created from a diagnosis will appear here.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}
