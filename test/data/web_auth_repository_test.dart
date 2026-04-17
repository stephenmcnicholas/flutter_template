import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/data/web_auth_repository.dart';
import 'package:fytter/src/domain/auth_exceptions.dart';

void main() {
  late WebAuthRepository repo;

  setUp(() {
    repo = WebAuthRepository();
  });

  test('currentUser returns null', () {
    expect(repo.currentUser(), isNull);
  });

  test('authStateChanges returns empty stream', () async {
    final events = await repo.authStateChanges().toList();
    expect(events, isEmpty);
  });

  test('reloadUser completes', () async {
    await repo.reloadUser();
  });

  test('signOut completes', () async {
    await repo.signOut();
  });

  test('signInWithEmail throws AuthNotSupported', () {
    expect(
      () => repo.signInWithEmail(email: 'a@b.com', password: 'x'),
      throwsA(isA<AuthNotSupported>()),
    );
  });

  test('signUpWithEmail throws AuthNotSupported', () {
    expect(
      () => repo.signUpWithEmail(email: 'a@b.com', password: 'x'),
      throwsA(isA<AuthNotSupported>()),
    );
  });

  test('signInWithGoogle throws AuthNotSupported', () {
    expect(
      () => repo.signInWithGoogle(),
      throwsA(isA<AuthNotSupported>()),
    );
  });

  test('sendEmailVerification throws AuthNotSupported', () {
    expect(
      () => repo.sendEmailVerification(),
      throwsA(isA<AuthNotSupported>()),
    );
  });

  test('sendPasswordReset throws AuthNotSupported', () {
    expect(
      () => repo.sendPasswordReset(email: 'a@b.com'),
      throwsA(isA<AuthNotSupported>()),
    );
  });
}
