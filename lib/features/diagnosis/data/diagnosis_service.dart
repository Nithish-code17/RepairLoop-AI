import '../domain/diagnosis.dart';

abstract interface class DiagnosisService {
  Future<Diagnosis> analyze({
    required String productId,
    required String symptoms,
    String? imageStoragePath,
  });

  Stream<List<Diagnosis>> watchForProduct(String productId);
}
