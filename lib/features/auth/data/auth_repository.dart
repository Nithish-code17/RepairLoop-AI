import 'package:firebase_auth/firebase_auth.dart';

import '../domain/app_user.dart';

abstract interface class AuthRepository {
  Stream<User?> authStateChanges();

  Future<UserCredential> signIn({
    required String email,
    required String password,
  });

  Future<UserCredential> register({
    required String displayName,
    required String email,
    required String password,
    required AppRole role,
  });

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();
}
