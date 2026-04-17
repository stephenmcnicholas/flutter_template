import 'package:fytter/src/domain/auth_repository.dart';
import 'package:fytter/src/domain/auth_user.dart';

/// Shared fake [AuthRepository] for widget and controller tests.
class TestAuthRepository implements AuthRepository {
  TestAuthRepository({
    this.signInEmail,
    this.signUpEmail,
    this.signInGoogle,
    this.sendVerification,
    this.reloadUserCallback,
    this.sendReset,
    this.signOutUser,
  });

  final Future<AuthUser> Function()? signInEmail;
  final Future<AuthUser> Function()? signUpEmail;
  final Future<AuthUser> Function()? signInGoogle;
  final Future<void> Function()? sendVerification;
  final Future<void> Function()? reloadUserCallback;
  final Future<void> Function()? sendReset;
  final Future<void> Function()? signOutUser;

  @override
  Stream<AuthUser?> authStateChanges() => const Stream.empty();

  @override
  AuthUser? currentUser() => null;

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) {
    return signInEmail?.call() ??
        Future.value(
          const AuthUser(
            uid: '1',
            email: 'test@example.com',
            displayName: 'Test',
            isEmailVerified: false,
          ),
        );
  }

  @override
  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
  }) {
    return signUpEmail?.call() ??
        Future.value(
          const AuthUser(
            uid: '2',
            email: 'new@example.com',
            displayName: 'New',
            isEmailVerified: false,
          ),
        );
  }

  @override
  Future<AuthUser> signInWithGoogle() {
    return signInGoogle?.call() ??
        Future.value(
          const AuthUser(
            uid: '3',
            email: 'google@example.com',
            displayName: 'Google',
            isEmailVerified: true,
          ),
        );
  }

  @override
  Future<void> sendEmailVerification() {
    return sendVerification?.call() ?? Future.value();
  }

  @override
  Future<void> reloadUser() {
    return reloadUserCallback?.call() ?? Future.value();
  }

  @override
  Future<void> sendPasswordReset({required String email}) {
    return sendReset?.call() ?? Future.value();
  }

  @override
  Future<void> signOut() {
    return signOutUser?.call() ?? Future.value();
  }
}
