import '../domain/diagnosis.dart';
import 'diagnosis_assessment.dart';

abstract final class DiagnosisSafetyPolicy {
  static const _hazardWarning =
      'Stop using the product. Disconnect external power only if it is safe to '
      'do so, keep away from heat and flammable materials, and contact a '
      'qualified technician or emergency service as appropriate.';

  static final _hazardPattern = RegExp(
    r'\b(smoke|smoking|spark|sparking|fire|burn|burned|burning|burnt|swollen|swelling|'
    r'bulging|hissing|electric shock|shocked|high[ -]?voltage|chemical smell|'
    r'battery leak|leaking battery|very hot|overheating)\b',
    caseSensitive: false,
  );

  static DiagnosisAssessment enforce({
    required String symptoms,
    required DiagnosisAssessment assessment,
  }) {
    final modelEvidence = [
      assessment.possibleIssue,
      assessment.reasoningSummary,
      assessment.recommendedAction,
      assessment.safetyWarning,
    ].join(' ');
    final modelAlsoFoundHazard = _hazardPattern.hasMatch(modelEvidence) ||
        (assessment.severity == DiagnosisSeverity.high &&
            assessment.safetyWarning.isNotEmpty);
    if (!_hazardPattern.hasMatch(symptoms) && !modelAlsoFoundHazard) {
      return assessment;
    }

    return assessment.copyWith(
      severity: DiagnosisSeverity.high,
      professionalServiceRecommended: true,
      safetyWarning: _hazardWarning,
      recommendedAction:
          'Do not continue troubleshooting or open the product. Isolate it '
          'safely and arrange an urgent professional inspection.',
    );
  }
}
