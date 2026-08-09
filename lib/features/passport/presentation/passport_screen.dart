import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/content_frame.dart';
import '../../../core/widgets/status_chip.dart';
import '../../diagnosis/domain/diagnosis.dart';
import '../../lifecycle/domain/lifecycle_event.dart';
import '../../products/domain/product.dart';
import '../../products/domain/product_component.dart';
import '../../repairs/domain/repair_case.dart';

class PassportScreen extends ConsumerWidget {
  const PassportScreen({required this.productId, super.key});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: const Text('Digital product passport')),
        body: ContentFrame(
          child: AsyncValueView(
            value: ref.watch(productProvider(productId)),
            data: (product) => product == null
                ? const Center(child: Text('Product passport not found.'))
                : _PassportContent(product: product),
          ),
        ),
      );
}

class _PassportContent extends ConsumerWidget {
  const _PassportContent({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final components =
        ref.watch(componentsProvider(product.id)).asData?.value ??
            const <ProductComponent>[];
    final diagnoses = ref.watch(diagnosesProvider(product.id)).asData?.value ??
        const <Diagnosis>[];
    final repairs = ref.watch(productRepairsProvider(product.id)).asData?.value ??
        const <RepairCase>[];
    final lifecycle = ref.watch(lifecycleProvider(product.id)).asData?.value ??
        const <LifecycleEvent>[];
    return ListView(
      children: [
        _PassportHeader(product: product),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            final details = _ProductDetails(product: product);
            final qr = _QrCard(product: product);
            return wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: details),
                      const SizedBox(width: 14),
                      SizedBox(width: 280, child: qr),
                    ],
                  )
                : Column(children: [details, const SizedBox(height: 14), qr]);
          },
        ),
        const SizedBox(height: 22),
        _Section(
          title: 'Components',
          description: 'Original and replacement parts recorded for this product.',
          child: components.isEmpty
              ? const _EmptySection('No component records have been added.')
              : Column(
                  children: components
                      .map((component) => _ComponentRow(component: component))
                      .toList(),
                ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Latest AI guidance',
          description: 'Preliminary assessment based on symptoms and product history.',
          action: FilledButton.icon(
            onPressed: () => context.push('/diagnosis/${product.id}'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New assessment'),
          ),
          child: diagnoses.isEmpty
              ? const _EmptySection('No AI-assisted assessments have been submitted.')
              : _DiagnosisSummary(diagnosis: diagnoses.first),
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Repair history',
          description: 'Service requests and technician-confirmed work.',
          child: repairs.isEmpty
              ? const _EmptySection('No repair work has been recorded.')
              : Column(
                  children: repairs
                      .map((repair) => _RepairRow(repair: repair))
                      .toList(),
                ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Lifecycle timeline',
          description: 'Chronological, append-only product activity.',
          child: lifecycle.isEmpty
              ? const _EmptySection('No lifecycle events are available.')
              : Column(
                  children: lifecycle
                      .map((event) => _LifecycleRow(event: event))
                      .toList(),
                ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

class _PassportHeader extends StatelessWidget {
  const _PassportHeader({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F1F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.devices_other,
                  color: Color(0xFF176B87),
                  size: 36,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        const StatusChip(
                          'VERIFIED PASSPORT',
                          tone: StatusTone.success,
                          icon: Icons.verified_outlined,
                        ),
                        StatusChip(
                          product.status.label.toUpperCase(),
                          tone: StatusTone.info,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(product.name, style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${product.brand} ${product.model} • ${product.category}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _ProductDetails extends StatelessWidget {
  const _ProductDetails({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              _DetailRow(label: 'Passport ID', value: product.passportId),
              _DetailRow(label: 'Serial number', value: product.serialNumber),
              _DetailRow(label: 'Category', value: product.category),
              _DetailRow(
                label: 'Purchase date',
                value: product.purchaseDate == null
                    ? 'Not recorded'
                    : DateFormat('dd MMM yyyy').format(product.purchaseDate!),
              ),
              _DetailRow(
                label: 'Warranty',
                value: product.warrantyEnd == null
                    ? 'Not recorded'
                    : '${product.isUnderWarranty ? 'Active' : 'Expired'} • '
                        '${DateFormat('dd MMM yyyy').format(product.warrantyEnd!)}',
                last: true,
              ),
            ],
          ),
        ),
      );
}

class _QrCard extends StatelessWidget {
  const _QrCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              QrImageView(
                data: 'repairloop://passport/${product.passportId}',
                size: 142,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 10),
              Text('Scan to open passport', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 3),
              Text(product.passportId, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      );
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.description,
    required this.child,
    this.action,
  });

  final String title;
  final String description;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 3),
                        Text(description, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  if (action != null) ...[
                    const SizedBox(width: 12),
                    action!,
                  ],
                ],
              ),
              const Divider(height: 28),
              child,
            ],
          ),
        ),
      );
}

class _ComponentRow extends StatelessWidget {
  const _ComponentRow({required this.component});

  final ProductComponent component;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFEEF1F3),
          child: Icon(Icons.memory_outlined, color: Color(0xFF53636E)),
        ),
        title: Text(component.name),
        subtitle: Text(
          '${component.partNumber.isEmpty ? 'Part number not recorded' : component.partNumber} • '
          '${component.isOriginal ? 'Original' : 'Replacement'}',
        ),
        trailing: StatusChip(
          component.condition.toUpperCase(),
          tone: component.replacedAt == null
              ? StatusTone.success
              : StatusTone.neutral,
        ),
      );
}

class _DiagnosisSummary extends StatelessWidget {
  const _DiagnosisSummary({required this.diagnosis});

  final Diagnosis diagnosis;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusChip(
                '${diagnosis.severity.name.toUpperCase()} SEVERITY',
                tone: diagnosis.severity == DiagnosisSeverity.high
                    ? StatusTone.danger
                    : diagnosis.severity == DiagnosisSeverity.medium
                        ? StatusTone.warning
                        : StatusTone.success,
              ),
              StatusChip('${(diagnosis.confidence * 100).round()}% CONFIDENCE'),
            ],
          ),
          const SizedBox(height: 12),
          Text(diagnosis.possibleIssue, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(diagnosis.reasoningSummary, style: Theme.of(context).textTheme.bodyMedium),
          if (diagnosis.safetyWarning.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              diagnosis.safetyWarning,
              style: const TextStyle(color: Color(0xFFB42318), fontWeight: FontWeight.w600),
            ),
          ],
        ],
      );
}

class _RepairRow extends StatelessWidget {
  const _RepairRow({required this.repair});

  final RepairCase repair;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE4F1F5),
          child: Icon(Icons.handyman_outlined, color: Color(0xFF176B87)),
        ),
        title: Text(repair.issueSummary),
        subtitle: Text(DateFormat('dd MMM yyyy').format(repair.updatedAt)),
        trailing: StatusChip(
          repair.status.label.toUpperCase(),
          tone: repair.status == RepairStatus.completed
              ? StatusTone.success
              : StatusTone.warning,
        ),
        onTap: () => context.push('/repairs/${repair.id}'),
      );
}

class _LifecycleRow extends StatelessWidget {
  const _LifecycleRow({required this.event});

  final LifecycleEvent event;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 3),
              child: Icon(Icons.circle, size: 10, color: Color(0xFF1C7C74)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('dd MMM yyyy, h:mm a').format(event.createdAt),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(event.description, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.last = false});

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: Color(0xFFDCE2E7))),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
}

class _EmptySection extends StatelessWidget {
  const _EmptySection(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
      );
}
