import '../domain/product.dart';
import '../domain/product_component.dart';
import '../../auth/domain/app_user.dart';

abstract interface class ProductRepository {
  Stream<List<Product>> watchProducts(AppUser user);

  Stream<Product?> watchProduct(String productId);

  Stream<List<ProductComponent>> watchComponents(String productId);

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
  });

  Future<String?> findProductIdByPassport(String passportId);
}
