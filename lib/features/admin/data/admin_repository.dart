import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../auth/domain/app_user.dart';

class AdminRepository {
  AdminRepository(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Stream<List<AppUser>> watchUsers() => _firestore
      .collection('users')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((document) => AppUser.fromMap(document.id, document.data()))
          .toList());

  Future<void> setRole(String userId, AppRole role) => _functions
      .httpsCallable('setUserRole')
      .call<Map<String, dynamic>>({'userId': userId, 'role': role.name});
}
