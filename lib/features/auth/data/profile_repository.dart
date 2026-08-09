import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/app_user.dart';

class ProfileRepository {
  ProfileRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<AppUser?> watchProfile(String userId) => _firestore
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((snapshot) => snapshot.data() == null
          ? null
          : AppUser.fromMap(snapshot.id, snapshot.data()!));
}
