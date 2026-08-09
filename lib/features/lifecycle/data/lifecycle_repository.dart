import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/lifecycle_event.dart';

class LifecycleRepository {
  LifecycleRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<List<LifecycleEvent>> watchForProduct(String productId) => _firestore
      .collection('lifecycleEvents')
      .where('productId', isEqualTo: productId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((document) =>
              LifecycleEvent.fromMap(document.id, document.data()))
          .toList());
}
