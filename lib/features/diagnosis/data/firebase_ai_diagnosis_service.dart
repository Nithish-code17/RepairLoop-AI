import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../../products/domain/product.dart';
import '../domain/diagnosis.dart';
import 'diagnosis_safety_policy.dart';
import 'diagnosis_service.dart';
import 'multimodal_diagnosis_provider.dart';

class FirebaseAiDiagnosisService implements DiagnosisService {
  FirebaseAiDiagnosisService(
    this._firestore,
    this._auth,
    this._provider,
  );

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final MultimodalDiagnosisProvider _provider;

  @override
  Future<Diagnosis> analyze({
    required Product product,
    required String symptoms,
    Uint8List? imageBytes,
    String? imageMimeType,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Sign in again before requesting an assessment.');
    }

    final assessment = await _provider.analyze(
      MultimodalDiagnosisRequest(
        product: product,
        symptoms: symptoms.trim(),
        imageBytes: imageBytes,
        imageMimeType: imageMimeType,
      ),
    );
    final safeAssessment = DiagnosisSafetyPolicy.enforce(
      symptoms: symptoms,
      assessment: assessment,
    );

    return Diagnosis(
      id: 'preview-${const Uuid().v4()}',
      productId: product.id,
      userId: user.uid,
      symptoms: symptoms.trim(),
      deviceSummary: safeAssessment.deviceSummary,
      possibleIssue: safeAssessment.possibleIssue,
      confidence: safeAssessment.confidence,
      reasoningSummary: safeAssessment.reasoningSummary,
      recommendedChecks: safeAssessment.recommendedChecks,
      recommendedAction: safeAssessment.recommendedAction,
      severity: safeAssessment.severity,
      professionalServiceRecommended:
          safeAssessment.professionalServiceRecommended,
      safetyWarning: safeAssessment.safetyWarning,
      createdAt: DateTime.now(),
    );
  }

  @override
  Stream<List<Diagnosis>> watchForProduct(String productId) => _firestore
      .collection('diagnoses')
      .where('productId', isEqualTo: productId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((document) => Diagnosis.fromMap(document.id, document.data()))
            .toList(),
      );
}
