import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/content_frame.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/domain/app_user.dart';
import '../../products/domain/product.dart';
import '../../repairs/domain/repair_case.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileValue = ref.watch(currentProfileProvider);
    final products = ref.watch(productsProvider).asData?.value ?? const <Product>[];
    final repairs = ref.watch(repairsProvider).asData?.value ?? const <RepairCase>[];

    return ContentFrame(
      child: AsyncValueView(
        value: profileValue,
        data: (profile) {
          if (profile == null) return const _SessionExpired();
          return ListView(
            children: [
              PageHeader(
                title: _title(profile.role),
                description: _description(profile.role),
                action: _primaryAction(context, profile.role),
              ),
              const SizedBox(height: 24),
              _Metrics(role: profile.role, products: products, repairs: repairs),
              const SizedBox(height: 24),
              _Workspace(role: profile.role, products: products, repairs: repairs),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  String _title(AppRole role) => switch (role) {
        AppRole.customer => 'Product overview',
        AppRole.manufacturer => 'Manufacturer workspace',
        AppRole.technician => 'Service queue',
        AppRole.admin => 'Platform operations',
      };

  String _description(AppRole role) => switch (role) {
        AppRole.customer => 'Your registered devices, warranty and active service work.',
        AppRole.manufacturer => 'Passports issued, model records and service activity.',
        AppRole.technician => 'Cases requiring inspection, parts or repair updates.',
        AppRole.admin => 'User access, product records and lifecycle activity.',
      };

  Widget? _primaryAction(BuildContext context, AppRole role) => switch (role) {
        AppRole.manufacturer => FilledButton.icon(
            onPressed: () => context.push('/products/new'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Register product'),
          ),
        AppRole.customer => FilledButton.icon(
            onPressed: () => context.go('/app/scan'),
            icon: const Icon(Icons.qr_code_scanner, size: 18),
            label: const Text('Scan passport'),
          ),
        AppRole.admin => FilledButton.icon(
            onPressed: () => context.push('/admin/users'),
            icon: const Icon(Icons.manage_accounts_outlined, size: 18),
            label: const Text('Manage users'),
          ),
        _ => null,
      };
}

class _Metrics extends StatelessWidget {
  const _Metrics({
    required this.role,
    required this.products,
    required this.repairs,
  });

  final AppRole role;
  final List<Product> products;
  final List<RepairCase> repairs;

  @override
  Widget build(BuildContext context) {
    final activeRepairs = repairs
        .where((repair) =>
            repair.status != RepairStatus.completed &&
            repair.status != RepairStatus.cancelled)
        .length;
    final completedRepairs = repairs
        .where((repair) => repair.status == RepairStatus.completed)
        .length;
    final metrics = [
      ('Products', products.length.toString(), Icons.inventory_2_outlined),
      ('Active repairs', activeRepairs.toString(), Icons.build_outlined),
      ('Completed', completedRepairs.toString(), Icons.task_alt_outlined),
      (
        role == AppRole.manufacturer ? 'Warranty active' : 'Records verified',
        products.where((product) => product.isUnderWarranty).length.toString(),
        Icons.verified_outlined,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 4 : 2;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: width,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(metric.$3, size: 20, color: const Color(0xFF176B87)),
                          const SizedBox(height: 16),
                          Text(
                            metric.$2,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(metric.$1, style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _Workspace extends StatelessWidget {
  const _Workspace({
    required this.role,
    required this.products,
    required this.repairs,
  });

  final AppRole role;
  final List<Product> products;
  final List<RepairCase> repairs;

  @override
  Widget build(BuildContext context) {
    if (role == AppRole.technician) {
      return _RepairQueue(repairs: repairs);
    }
    if (role == AppRole.admin) {
      return const _AdminOperations();
    }
    return _RecentProducts(products: products);
  }
}

class _RecentProducts extends StatelessWidget {
  const _RecentProducts({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Recent product records',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/app/products'),
                    child: const Text('View all'),
                  ),
                ],
              ),
              const Divider(),
              if (products.isEmpty)
                const _EmptyRow(
                  icon: Icons.inventory_2_outlined,
                  text: 'No product passports are connected yet.',
                )
              else
                ...products.take(4).map(
                      (product) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE4F1F5),
                          child: Icon(Icons.devices_other, color: Color(0xFF176B87)),
                        ),
                        title: Text(product.name),
                        subtitle: Text('${product.brand} ${product.model} • ${product.passportId}'),
                        trailing: StatusChip(
                          product.status.label.toUpperCase(),
                          tone: product.status == ProductStatus.repaired
                              ? StatusTone.success
                              : StatusTone.info,
                        ),
                        onTap: () => context.push('/passport/${product.id}'),
                      ),
                    ),
            ],
          ),
        ),
      );
}

class _RepairQueue extends StatelessWidget {
  const _RepairQueue({required this.repairs});

  final List<RepairCase> repairs;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Priority queue', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Open cases ordered by their latest activity.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Divider(height: 28),
              if (repairs.isEmpty)
                const _EmptyRow(
                  icon: Icons.task_alt,
                  text: 'There are no open repair cases.',
                )
              else
                ...repairs.take(6).map(
                      (repair) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(repair.issueSummary),
                        subtitle: Text(
                          'Case ${repair.id.substring(0, repair.id.length < 8 ? repair.id.length : 8)}',
                        ),
                        trailing: StatusChip(
                          repair.status.label.toUpperCase(),
                          tone: StatusTone.warning,
                        ),
                        onTap: () => context.push('/repairs/${repair.id}'),
                      ),
                    ),
            ],
          ),
        ),
      );
}

class _AdminOperations extends StatelessWidget {
  const _AdminOperations();

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Access controls', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                'Technician and administrator roles are granted through protected '
                'backend operations. Self-registration cannot create privileged users.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              const Row(
                children: [
                  StatusChip('SECURITY RULES ACTIVE', tone: StatusTone.success),
                  SizedBox(width: 8),
                  StatusChip('AUDIT EVENTS ENABLED', tone: StatusTone.info),
                ],
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () => context.push('/admin/users'),
                icon: const Icon(Icons.manage_accounts_outlined, size: 18),
                label: const Text('Review user roles'),
              ),
            ],
          ),
        ),
      );
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 26),
        child: Center(
          child: Column(
            children: [
              Icon(icon, size: 34, color: const Color(0xFF60717D)),
              const SizedBox(height: 10),
              Text(text, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      );
}

class _SessionExpired extends StatelessWidget {
  const _SessionExpired();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_clock_outlined, size: 42),
            const SizedBox(height: 12),
            const Text('Your session is not available.'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.go('/login'),
              child: const Text('Return to sign in'),
            ),
          ],
        ),
      );
}
