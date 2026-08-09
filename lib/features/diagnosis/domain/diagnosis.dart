import 'package:cloud_firestore/cloud_firestore.dart';

enum DiagnosisSeverity {
  low,
  medium,
  high;

  static DiagnosisSeverity fromValue(String? value) =>
      DiagnosisSeverity.values.firstWhere(
        (severity) => severity.name == value,
        orElse: () => DiagnosisSeverity.medium,
      );
}

class Diagnosis {
  const Diagnosis({
    required this.id,
    required this.productId,
    required this.userId,
    required this.symptoms,
    required this.deviceSummary,
    required this.possibleIssue,
    required this.confidence,
    required this.reasoningSummary,
    required this.recommendedChecks,
    required this.recommendedAction,
    required this.severity,
    required this.professionalServiceRecommended,
    required this.safetyWarning,
    required this.createdAt,
    this.imageUrl,
  });

  final String id;
  final String productId;
  final String userId;
  final String symptoms;
  final String deviceSummary;
  final String possibleIssue;
  final double confidence;
  final String reasoningSummary;
  final List<String> recommendedChecks;
  final String recommendedAction;
  final DiagnosisSeverity severity;
  final bool professionalServiceRecommended;
  final String safetyWarning;
  final DateTime createdAt;
  final String? imageUrl;

  factory Diagnosis.fromMap(String id, Map<String, dynamic> data) => Diagnosis(
        id: id,
        productId: data['productId'] as String? ?? '',
        userId: data['userId'] as String? ?? '',
        symptoms: data['symptoms'] as String? ?? '',
        deviceSummary: data['deviceSummary'] as String? ?? '',
        possibleIssue: data['possibleIssue'] as String? ?? '',
        confidence: (data['confidence'] as num?)?.toDouble() ?? 0,
        reasoningSummary: data['reasoningSummary'] as String? ?? '',
        recommendedChecks: List<String>.from(
          data['recommendedChecks'] as List<dynamic>? ?? const [],
        ),
        recommendedAction: data['recommendedAction'] as String? ?? '',
        severity: DiagnosisSeverity.fromValue(data['severity'] as String?),
        professionalServiceRecommended:
            data['professionalServiceRecommended'] as bool? ?? true,
        safetyWarning: data['safetyWarning'] as String? ?? '',
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        imageUrl: data['imageUrl'] as String?,
      );
}
