import 'package:fytter/src/domain/auth_repository.dart';
import 'package:fytter/src/domain/auth_user.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  Stream<AuthUser?> authStateChanges() => Stream.value(null);

  @override
  AuthUser? currentUser() => null;

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AuthUser> signInWithGoogle() {
    throw UnimplementedError();
  }

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<void> reloadUser() async {}

  @override
  Future<void> sendPasswordReset({required String email}) async {}

  @override
  Future<void> signOut() async {}
}
