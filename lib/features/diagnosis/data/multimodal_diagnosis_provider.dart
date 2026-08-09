import 'dart:typed_data';

import '../../products/domain/product.dart';
import 'diagnosis_assessment.dart';

class MultimodalDiagnosisRequest {
  const MultimodalDiagnosisRequest({
    required this.product,
    required this.symptoms,
    this.imageBytes,
    this.imageMimeType,
  });

  final Product product;
  final String symptoms;
  final Uint8List? imageBytes;
  final String? imageMimeType;
}

abstract interface class MultimodalDiagnosisProvider {
  Future<DiagnosisAssessment> analyze(MultimodalDiagnosisRequest request);
}
