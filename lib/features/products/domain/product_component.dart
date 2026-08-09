import 'package:cloud_firestore/cloud_firestore.dart';

class ProductComponent {
  const ProductComponent({
    required this.id,
    required this.productId,
    required this.name,
    required this.partNumber,
    required this.condition,
    required this.isOriginal,
    required this.installedAt,
    this.replacedAt,
  });

  final String id;
  final String productId;
  final String name;
  final String partNumber;
  final String condition;
  final bool isOriginal;
  final DateTime installedAt;
  final DateTime? replacedAt;

  factory ProductComponent.fromMap(String id, Map<String, dynamic> data) =>
      ProductComponent(
        id: id,
        productId: data['productId'] as String? ?? '',
        name: data['name'] as String? ?? 'Component',
        partNumber: data['partNumber'] as String? ?? '',
        condition: data['condition'] as String? ?? 'active',
        isOriginal: data['isOriginal'] as bool? ?? false,
        installedAt:
            (data['installedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        replacedAt: (data['replacedAt'] as Timestamp?)?.toDate(),
      );
}

class NewProductComponent {
  const NewProductComponent({required this.name, required this.partNumber});

  final String name;
  final String partNumber;
}
