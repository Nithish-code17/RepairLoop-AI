import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../domain/diagnosis.dart';
import 'diagnosis_service.dart';

class FirebaseFunctionsDiagnosisService implements DiagnosisService {
  FirebaseFunctionsDiagnosisService(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  @override
  Future<Diagnosis> analyze({
    required String productId,
    required String symptoms,
    String? imageStoragePath,
  }) async {
    final callable = _functions.httpsCallable(
      'analyzeDiagnosis',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
    );
    final response = await callable.call<Map<String, dynamic>>({
      'productId': productId,
      'symptoms': symptoms.trim(),
      'imageStoragePath': imageStoragePath,
    });
    final diagnosisId = response.data['diagnosisId'] as String;
    final snapshot =
        await _firestore.collection('diagnoses').doc(diagnosisId).get();
    return Diagnosis.fromMap(snapshot.id, snapshot.data()!);
  }

  @override
  Stream<List<Diagnosis>> watchForProduct(String productId) => _firestore
      .collection('diagnoses')
      .where('productId', isEqualTo: productId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((document) => Diagnosis.fromMap(document.id, document.data()))
          .toList());
}
