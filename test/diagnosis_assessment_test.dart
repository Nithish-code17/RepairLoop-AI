import 'package:flutter_test/flutter_test.dart';
import 'package:repairloop_ai/features/diagnosis/data/diagnosis_assessment.dart';
import 'package:repairloop_ai/features/diagnosis/data/diagnosis_safety_policy.dart';
import 'package:repairloop_ai/features/diagnosis/domain/diagnosis.dart';

void main() {
  group('DiagnosisAssessment', () {
    test('parses structured AI output and clamps confidence', () {
      final assessment = DiagnosisAssessment.fromJson({
        'deviceSummary': 'Laptop with an intermittent display fault',
        'possibleIssue': 'Loose or damaged display connection',
        'confidence': 1.4,
        'reasoningSummary': 'The display changes when the lid moves.',
        'recommendedChecks': [
          'Restart the device',
          'Test with an external monitor',
        ],
        'recommendedAction': 'Arrange an inspection if the issue continues.',
        'severity': 'medium',
        'professionalServiceRecommended': true,
        'safetyWarning': '',
      });

      expect(assessment.confidence, 1);
      expect(assessment.severity, DiagnosisSeverity.medium);
      expect(assessment.recommendedChecks, hasLength(2));
    });

    test('rejects an assessment without safe checks', () {
      expect(
        () => DiagnosisAssessment.fromJson({
          'deviceSummary': 'Phone',
          'possibleIssue': 'Unknown',
          'confidence': 0.2,
          'reasoningSummary': 'Insufficient evidence',
          'recommendedChecks': <String>[],
          'recommendedAction': 'Seek service',
          'severity': 'low',
          'professionalServiceRecommended': false,
          'safetyWarning': '',
        }),
        throwsFormatException,
      );
    });
  });

  group('DiagnosisSafetyPolicy', () {
    test('forces high severity for a swollen battery report', () {
      const original = DiagnosisAssessment(
        deviceSummary: 'Mobile phone',
        possibleIssue: 'Battery wear',
        confidence: 0.6,
        reasoningSummary: 'The battery is not performing normally.',
        recommendedChecks: ['Restart the phone'],
        recommendedAction: 'Monitor the phone.',
        severity: DiagnosisSeverity.low,
        professionalServiceRecommended: false,
        safetyWarning: '',
      );

      final enforced = DiagnosisSafetyPolicy.enforce(
        symptoms: 'The battery is swollen and the phone is very hot.',
        assessment: original,
      );

      expect(enforced.severity, DiagnosisSeverity.high);
      expect(enforced.professionalServiceRecommended, isTrue);
      expect(enforced.safetyWarning, isNotEmpty);
      expect(enforced.recommendedAction, contains('Do not'));
    });

    test('keeps a low-risk assessment unchanged', () {
      const original = DiagnosisAssessment(
        deviceSummary: 'Wireless mouse',
        possibleIssue: 'Low battery',
        confidence: 0.8,
        reasoningSummary: 'The pointer disconnects intermittently.',
        recommendedChecks: ['Replace the removable battery'],
        recommendedAction: 'Test with a known-good battery.',
        severity: DiagnosisSeverity.low,
        professionalServiceRecommended: false,
        safetyWarning: '',
      );

      final enforced = DiagnosisSafetyPolicy.enforce(
        symptoms: 'The pointer sometimes stops moving.',
        assessment: original,
      );

      expect(identical(enforced, original), isTrue);
    });

    test('honors a hazard detected from image evidence by the model', () {
      const original = DiagnosisAssessment(
        deviceSummary: 'Power adapter',
        possibleIssue: 'Visible burn damage near the cable',
        confidence: 0.9,
        reasoningSummary: 'The image shows a damaged connector.',
        recommendedChecks: ['Stop using the adapter'],
        recommendedAction: 'Replace the adapter.',
        severity: DiagnosisSeverity.medium,
        professionalServiceRecommended: false,
        safetyWarning: '',
      );

      final enforced = DiagnosisSafetyPolicy.enforce(
        symptoms: 'The cable no longer works reliably.',
        assessment: original,
      );

      expect(enforced.severity, DiagnosisSeverity.high);
      expect(enforced.professionalServiceRecommended, isTrue);
    });
  });
}
