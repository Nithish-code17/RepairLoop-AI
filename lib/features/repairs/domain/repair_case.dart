import 'package:cloud_firestore/cloud_firestore.dart';

enum RepairStatus {
  requested,
  accepted,
  inspecting,
  awaitingParts,
  repairing,
  completed,
  cancelled;

  String get label => switch (this) {
        RepairStatus.requested => 'Requested',
        RepairStatus.accepted => 'Accepted',
        RepairStatus.inspecting => 'Inspecting',
        RepairStatus.awaitingParts => 'Awaiting parts',
        RepairStatus.repairing => 'Repairing',
        RepairStatus.completed => 'Completed',
        RepairStatus.cancelled => 'Cancelled',
      };

  static RepairStatus fromValue(String? value) => RepairStatus.values.firstWhere(
        (status) => status.name == value,
        orElse: () => RepairStatus.requested,
      );
}

class RepairCase {
  const RepairCase({
    required this.id,
    required this.productId,
    required this.ownerId,
    required this.diagnosisId,
    required this.status,
    required this.issueSummary,
    required this.createdAt,
    required this.updatedAt,
    this.technicianId,
    this.technicianNotes,
    this.completedAt,
  });

  final String id;
  final String productId;
  final String ownerId;
  final String diagnosisId;
  final String? technicianId;
  final RepairStatus status;
  final String issueSummary;
  final String? technicianNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  factory RepairCase.fromMap(String id, Map<String, dynamic> data) => RepairCase(
        id: id,
        productId: data['productId'] as String? ?? '',
        ownerId: data['ownerId'] as String? ?? '',
        diagnosisId: data['diagnosisId'] as String? ?? '',
        technicianId: data['technicianId'] as String?,
        status: RepairStatus.fromValue(data['status'] as String?),
        issueSummary: data['issueSummary'] as String? ?? '',
        technicianNotes: data['technicianNotes'] as String?,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      );
}
