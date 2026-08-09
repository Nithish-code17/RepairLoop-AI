import 'package:cloud_firestore/cloud_firestore.dart';

class LifecycleEvent {
  const LifecycleEvent({
    required this.id,
    required this.productId,
    required this.type,
    required this.title,
    required this.description,
    required this.actorId,
    required this.createdAt,
  });

  final String id;
  final String productId;
  final String type;
  final String title;
  final String description;
  final String actorId;
  final DateTime createdAt;

  factory LifecycleEvent.fromMap(String id, Map<String, dynamic> data) =>
      LifecycleEvent(
        id: id,
        productId: data['productId'] as String? ?? '',
        type: data['type'] as String? ?? 'update',
        title: data['title'] as String? ?? 'Lifecycle update',
        description: data['description'] as String? ?? '',
        actorId: data['actorId'] as String? ?? '',
        createdAt:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}
