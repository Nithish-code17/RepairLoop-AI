import '../domain/diagnosis.dart';

class DiagnosisAssessment {
  const DiagnosisAssessment({
    required this.deviceSummary,
    required this.possibleIssue,
    required this.confidence,
    required this.reasoningSummary,
    required this.recommendedChecks,
    required this.recommendedAction,
    required this.severity,
    required this.professionalServiceRecommended,
    required this.safetyWarning,
  });

  final String deviceSummary;
  final String possibleIssue;
  final double confidence;
  final String reasoningSummary;
  final List<String> recommendedChecks;
  final String recommendedAction;
  final DiagnosisSeverity severity;
  final bool professionalServiceRecommended;
  final String safetyWarning;

  factory DiagnosisAssessment.fromJson(Map<String, dynamic> json) {
    final checks = (json['recommendedChecks'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .take(5)
        .toList(growable: false);

    if (checks.isEmpty) {
      throw const FormatException(
        'The assessment did not include any recommended checks.',
      );
    }

    return DiagnosisAssessment(
      deviceSummary: _requiredString(json, 'deviceSummary'),
      possibleIssue: _requiredString(json, 'possibleIssue'),
      confidence: ((json['confidence'] as num?)?.toDouble() ?? 0.5)
          .clamp(0.0, 1.0)
          .toDouble(),
      reasoningSummary: _requiredString(json, 'reasoningSummary'),
      recommendedChecks: checks,
      recommendedAction: _requiredString(json, 'recommendedAction'),
      severity: DiagnosisSeverity.fromValue(json['severity'] as String?),
      professionalServiceRecommended:
          json['professionalServiceRecommended'] as bool? ?? true,
      safetyWarning: (json['safetyWarning'] as String? ?? '').trim(),
    );
  }

  DiagnosisAssessment copyWith({
    String? possibleIssue,
    double? confidence,
    List<String>? recommendedChecks,
    String? recommendedAction,
    DiagnosisSeverity? severity,
    bool? professionalServiceRecommended,
    String? safetyWarning,
  }) =>
      DiagnosisAssessment(
        deviceSummary: deviceSummary,
        possibleIssue: possibleIssue ?? this.possibleIssue,
        confidence: confidence ?? this.confidence,
        reasoningSummary: reasoningSummary,
        recommendedChecks: recommendedChecks ?? this.recommendedChecks,
        recommendedAction: recommendedAction ?? this.recommendedAction,
        severity: severity ?? this.severity,
        professionalServiceRecommended: professionalServiceRecommended ??
            this.professionalServiceRecommended,
        safetyWarning: safetyWarning ?? this.safetyWarning,
      );

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = (json[key] as String? ?? '').trim();
    if (value.isEmpty) {
      throw FormatException('The assessment is missing $key.');
    }
    return value;
  }
}
