import '../../auth/domain/app_user.dart';
import '../domain/repair_case.dart';

abstract interface class RepairRepository {
  Stream<List<RepairCase>> watchRepairs(AppUser user);

  Stream<List<RepairCase>> watchForProduct(String productId);

  Future<String> createRequest({
    required String productId,
    required String diagnosisId,
    required String issueSummary,
  });

  Future<void> updateStatus({
    required String repairId,
    required RepairStatus status,
    String? technicianNotes,
  });

  Future<void> recordComponentReplacement({
    required String repairId,
    String? oldComponentId,
    required String name,
    required String partNumber,
  });
}
