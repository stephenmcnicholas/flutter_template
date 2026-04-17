import 'dart:async';

import 'package:fytter/src/domain/auth_exceptions.dart';
import 'package:fytter/src/domain/auth_repository.dart';
import 'package:fytter/src/domain/auth_user.dart';

class WebAuthRepository implements AuthRepository {
  @override
  Stream<AuthUser?> authStateChanges() {
    return const Stream<AuthUser?>.empty();
  }

  @override
  AuthUser? currentUser() {
    return null;
  }

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) {
    throw const AuthNotSupported();
  }

  @override
  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
  }) {
    throw const AuthNotSupported();
  }

  @override
  Future<AuthUser> signInWithGoogle() {
    throw const AuthNotSupported();
  }

  @override
  Future<void> sendEmailVerification() {
    throw const AuthNotSupported();
  }

  @override
  Future<void> reloadUser() async {}

  @override
  Future<void> sendPasswordReset({required String email}) {
    throw const AuthNotSupported();
  }

  @override
  Future<void> signOut() async {}
}
