import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../auth/domain/app_user.dart';
import '../domain/repair_case.dart';
import 'repair_repository.dart';

class FirestoreRepairRepository implements RepairRepository {
  FirestoreRepairRepository(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  @override
  Stream<List<RepairCase>> watchRepairs(AppUser user) {
    Query<Map<String, dynamic>> query = _firestore.collection('repairs');
    query = switch (user.role) {
      AppRole.customer => query.where('ownerId', isEqualTo: user.id),
      AppRole.technician => query.where(
          'status',
          whereIn: RepairStatus.values
              .where((status) => status != RepairStatus.cancelled)
              .map((status) => status.name)
              .toList(),
        ),
      AppRole.manufacturer =>
        query.where('manufacturerId', isEqualTo: user.id),
      AppRole.admin => query,
    };
    return query
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((document) => RepairCase.fromMap(document.id, document.data()))
            .toList());
  }

  @override
  Stream<List<RepairCase>> watchForProduct(String productId) => _firestore
      .collection('repairs')
      .where('productId', isEqualTo: productId)
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((document) => RepairCase.fromMap(document.id, document.data()))
          .toList());

  @override
  Future<String> createRequest({
    required String productId,
    required String diagnosisId,
    required String issueSummary,
  }) async {
    final result = await _functions
        .httpsCallable('createRepairRequest')
        .call<Map<String, dynamic>>({
      'productId': productId,
      'diagnosisId': diagnosisId,
      'issueSummary': issueSummary.trim(),
    });
    return result.data['repairId'] as String;
  }

  @override
  Future<void> updateStatus({
    required String repairId,
    required RepairStatus status,
    String? technicianNotes,
  }) async {
    await _functions
        .httpsCallable('updateRepairStatus')
        .call<Map<String, dynamic>>({
      'repairId': repairId,
      'status': status.name,
      'technicianNotes': technicianNotes?.trim(),
    });
  }

  @override
  Future<void> recordComponentReplacement({
    required String repairId,
    String? oldComponentId,
    required String name,
    required String partNumber,
  }) async {
    await _functions
        .httpsCallable('recordComponentReplacement')
        .call<Map<String, dynamic>>({
      'repairId': repairId,
      'oldComponentId': oldComponentId,
      'name': name.trim(),
      'partNumber': partNumber.trim(),
      'condition': 'active',
    });
  }
}
