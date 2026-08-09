import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../auth/domain/app_user.dart';
import '../domain/product.dart';
import '../domain/product_component.dart';
import 'product_repository.dart';

class FirestoreProductRepository implements ProductRepository {
  FirestoreProductRepository(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  @override
  Stream<List<Product>> watchProducts(AppUser user) {
    Query<Map<String, dynamic>> query = _firestore.collection('products');
    query = switch (user.role) {
      AppRole.customer => query.where('ownerId', isEqualTo: user.id),
      AppRole.manufacturer =>
        query.where('manufacturerId', isEqualTo: user.id),
      AppRole.technician || AppRole.admin => query,
    };
    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((document) => Product.fromMap(document.id, document.data()))
            .toList());
  }

  @override
  Stream<Product?> watchProduct(String productId) => _firestore
      .collection('products')
      .doc(productId)
      .snapshots()
      .map((snapshot) => snapshot.data() == null
          ? null
          : Product.fromMap(snapshot.id, snapshot.data()!));

  @override
  Stream<List<ProductComponent>> watchComponents(String productId) => _firestore
      .collection('products')
      .doc(productId)
      .collection('components')
      .orderBy('installedAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((document) =>
              ProductComponent.fromMap(document.id, document.data()))
          .toList());

  @override
  Future<String> registerProduct({
    required String name,
    required String brand,
    required String model,
    required String category,
    required String serialNumber,
    required String ownerEmail,
    required List<NewProductComponent> components,
    DateTime? purchaseDate,
    DateTime? warrantyEnd,
  }) async {
    final callable = _functions.httpsCallable('registerProduct');
    final result = await callable.call<Map<String, dynamic>>({
      'name': name.trim(),
      'brand': brand.trim(),
      'model': model.trim(),
      'category': category,
      'serialNumber': serialNumber.trim(),
      'ownerEmail': ownerEmail.trim().toLowerCase(),
      'components': components
          .map((component) => {
                'name': component.name.trim(),
                'partNumber': component.partNumber.trim(),
              })
          .toList(),
      'purchaseDate': purchaseDate?.toIso8601String(),
      'warrantyEnd': warrantyEnd?.toIso8601String(),
    });
    return result.data['productId'] as String;
  }

  @override
  Future<String?> findProductIdByPassport(String passportId) async {
    final snapshot = await _firestore
        .collection('products')
        .where('passportId', isEqualTo: passportId.trim().toUpperCase())
        .limit(1)
        .get();
    return snapshot.docs.isEmpty ? null : snapshot.docs.first.id;
  }
}
