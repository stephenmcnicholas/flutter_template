import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/auth_exceptions.dart';

void main() {
  test('AuthActionCanceled default message', () {
    expect(const AuthActionCanceled().toString(), 'Sign-in canceled');
  });

  test('AuthActionCanceled custom message', () {
    expect(const AuthActionCanceled('Canceled').toString(), 'Canceled');
  });

  test('AuthNotSupported default message', () {
    expect(
      const AuthNotSupported().toString(),
      'Sign-in not supported on web demo',
    );
  });

  test('AuthNotSupported custom message', () {
    expect(const AuthNotSupported('Nope').toString(), 'Nope');
  });
}
