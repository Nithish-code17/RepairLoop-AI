import 'dart:typed_data';

import '../../products/domain/product.dart';
import '../domain/diagnosis.dart';

abstract interface class DiagnosisService {
  Future<Diagnosis> analyze({
    required Product product,
    required String symptoms,
    Uint8List? imageBytes,
    String? imageMimeType,
  });

  Stream<List<Diagnosis>> watchForProduct(String productId);
}
