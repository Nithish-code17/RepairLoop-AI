import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/content_frame.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/domain/app_user.dart';
import '../domain/product.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentProfileProvider).asData?.value?.role;
    return ContentFrame(
      child: Column(
        children: [
          PageHeader(
            title: role == AppRole.manufacturer
                ? 'Product passports'
                : 'Connected products',
            description: role == AppRole.manufacturer
                ? 'Products registered by your organization.'
                : 'Devices available to your RepairLoop account.',
            action: role == AppRole.manufacturer
                ? FilledButton.icon(
                    onPressed: () => context.push('/products/new'),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Register product'),
                  )
                : null,
          ),
          const SizedBox(height: 22),
          Expanded(
            child: AsyncValueView(
              value: ref.watch(productsProvider),
              data: (products) => products.isEmpty
                  ? _EmptyProducts(role: role)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 900 ? 3 : 1;
                        final ratio = columns == 1 ? 3.1 : 1.35;
                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: ratio,
                          ),
                          itemCount: products.length,
                          itemBuilder: (context, index) =>
                              _ProductCard(product: products[index]),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push('/passport/${product.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4F1F5),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.devices_other,
                    color: Color(0xFF176B87),
                    size: 29,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 20),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${product.brand} ${product.model}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const Spacer(),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          StatusChip(
                            product.status.label.toUpperCase(),
                            tone: product.status == ProductStatus.repaired
                                ? StatusTone.success
                                : StatusTone.info,
                          ),
                          StatusChip(product.passportId),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts({required this.role});

  final AppRole? role;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 44,
              color: Color(0xFF60717D),
            ),
            const SizedBox(height: 12),
            Text('No products found', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              role == AppRole.manufacturer
                  ? 'Register the first product to issue its digital passport.'
                  : 'Scan a RepairLoop passport to connect a product.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            if (role == AppRole.manufacturer)
              FilledButton(
                onPressed: () => context.push('/products/new'),
                child: const Text('Register product'),
              )
            else
              FilledButton.icon(
                onPressed: () => context.go('/app/scan'),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan passport'),
              ),
          ],
        ),
      );
}
