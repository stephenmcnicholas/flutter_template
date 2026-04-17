import 'package:fytter/src/domain/auth_user.dart';

abstract class AuthRepository {
  Stream<AuthUser?> authStateChanges();
  AuthUser? currentUser();

  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
  });

  Future<AuthUser> signInWithGoogle();

  Future<void> sendEmailVerification();
  Future<void> reloadUser();
  Future<void> sendPasswordReset({required String email});
  Future<void> signOut();
}
