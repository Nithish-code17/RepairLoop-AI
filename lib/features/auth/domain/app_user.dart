import 'package:cloud_firestore/cloud_firestore.dart';

enum AppRole {
  customer,
  manufacturer,
  technician,
  admin;

  String get label => switch (this) {
        AppRole.customer => 'Customer',
        AppRole.manufacturer => 'Manufacturer',
        AppRole.technician => 'Technician',
        AppRole.admin => 'Administrator',
      };

  static AppRole fromValue(String? value) => AppRole.values.firstWhere(
        (role) => role.name == value,
        orElse: () => AppRole.customer,
      );
}

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String displayName;
  final AppRole role;
  final DateTime createdAt;

  factory AppUser.fromMap(String id, Map<String, dynamic> data) => AppUser(
        id: id,
        email: data['email'] as String? ?? '',
        displayName: data['displayName'] as String? ?? 'RepairLoop user',
        role: AppRole.fromValue(data['role'] as String?),
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'email': email,
        'displayName': displayName,
        'role': role.name,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
