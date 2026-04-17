import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/auth_exceptions.dart';
import 'package:fytter/src/providers/auth_providers.dart';
import '../support/test_auth_repository.dart';

void main() {
  test('clears loading on successful sign-in', () async {
    final controller = AuthController(TestAuthRepository());
    final success = await controller.signInWithEmail(
      email: 'test@example.com',
      password: 'password',
    );

    expect(success, isTrue);
    expect(controller.state.isLoading, isFalse);
    expect(controller.state.errorMessage, isNull);
  });

  test('maps FirebaseAuthException to message', () async {
    final controller = AuthController(TestAuthRepository(
      signInEmail: () async {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Invalid email',
        );
      },
    ));

    final success = await controller.signInWithEmail(
      email: 'bad',
      password: 'password',
    );

    expect(success, isFalse);
    expect(controller.state.errorMessage, 'Enter a valid email address.');
  });

  test('ignores canceled auth actions', () async {
    final controller = AuthController(TestAuthRepository(
      signInGoogle: () async => throw const AuthActionCanceled(),
    ));

    final success = await controller.signInWithGoogle();

    expect(success, isFalse);
    expect(controller.state.errorMessage, isNull);
  });
}
