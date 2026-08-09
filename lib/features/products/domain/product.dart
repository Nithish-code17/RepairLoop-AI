import 'package:cloud_firestore/cloud_firestore.dart';

enum ProductStatus {
  active,
  diagnosisPending,
  repairPending,
  underRepair,
  repaired,
  retired;

  String get label => switch (this) {
        ProductStatus.active => 'Active',
        ProductStatus.diagnosisPending => 'Diagnosis pending',
        ProductStatus.repairPending => 'Repair requested',
        ProductStatus.underRepair => 'Under repair',
        ProductStatus.repaired => 'Repaired',
        ProductStatus.retired => 'Retired',
      };

  static ProductStatus fromValue(String? value) => ProductStatus.values.firstWhere(
        (status) => status.name == value,
        orElse: () => ProductStatus.active,
      );
}

class Product {
  const Product({
    required this.id,
    required this.passportId,
    required this.ownerId,
    required this.manufacturerId,
    required this.name,
    required this.brand,
    required this.model,
    required this.category,
    required this.serialNumber,
    required this.status,
    required this.purchaseDate,
    required this.warrantyEnd,
    required this.createdAt,
    this.imageUrl,
  });

  final String id;
  final String passportId;
  final String ownerId;
  final String manufacturerId;
  final String name;
  final String brand;
  final String model;
  final String category;
  final String serialNumber;
  final ProductStatus status;
  final DateTime? purchaseDate;
  final DateTime? warrantyEnd;
  final DateTime createdAt;
  final String? imageUrl;

  bool get isUnderWarranty =>
      warrantyEnd != null && warrantyEnd!.isAfter(DateTime.now());

  factory Product.fromMap(String id, Map<String, dynamic> data) => Product(
        id: id,
        passportId: data['passportId'] as String? ?? '',
        ownerId: data['ownerId'] as String? ?? '',
        manufacturerId: data['manufacturerId'] as String? ?? '',
        name: data['name'] as String? ?? 'Unnamed product',
        brand: data['brand'] as String? ?? '',
        model: data['model'] as String? ?? '',
        category: data['category'] as String? ?? 'Other',
        serialNumber: data['serialNumber'] as String? ?? '',
        status: ProductStatus.fromValue(data['status'] as String?),
        purchaseDate: (data['purchaseDate'] as Timestamp?)?.toDate(),
        warrantyEnd: (data['warrantyEnd'] as Timestamp?)?.toDate(),
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        imageUrl: data['imageUrl'] as String?,
      );
}
