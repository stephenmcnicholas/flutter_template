import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/data/firebase_auth_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

void main() {
  late MockFirebaseAuth mockAuth;
  late FirebaseAuthRepository repo;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    repo = FirebaseAuthRepository(auth: mockAuth);
  });

  test('currentUser returns null when Firebase has no user', () {
    when(() => mockAuth.currentUser).thenReturn(null);
    expect(repo.currentUser(), isNull);
  });

  test('currentUser maps Firebase user to AuthUser', () {
    final user = MockUser();
    when(() => mockAuth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn('uid1');
    when(() => user.email).thenReturn('a@b.com');
    when(() => user.displayName).thenReturn('Alice');
    when(() => user.photoURL).thenReturn(null);
    when(() => user.emailVerified).thenReturn(true);

    final u = repo.currentUser();
    expect(u, isNotNull);
    expect(u!.uid, 'uid1');
    expect(u.email, 'a@b.com');
    expect(u.isEmailVerified, isTrue);
  });

  test('signInWithEmail returns mapped user', () async {
    final user = MockUser();
    final cred = MockUserCredential();
    when(
      () => mockAuth.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => cred);
    when(() => cred.user).thenReturn(user);
    when(() => user.uid).thenReturn('u1');
    when(() => user.email).thenReturn('x@y.com');
    when(() => user.displayName).thenReturn(null);
    when(() => user.photoURL).thenReturn(null);
    when(() => user.emailVerified).thenReturn(false);

    final out = await repo.signInWithEmail(email: 'x@y.com', password: 'secret');
    expect(out.uid, 'u1');
    verify(
      () => mockAuth.signInWithEmailAndPassword(email: 'x@y.com', password: 'secret'),
    ).called(1);
  });

  test('sendPasswordReset delegates to FirebaseAuth', () async {
    when(() => mockAuth.sendPasswordResetEmail(email: any(named: 'email')))
        .thenAnswer((_) async {});
    await repo.sendPasswordReset(email: 'a@b.com');
    verify(() => mockAuth.sendPasswordResetEmail(email: 'a@b.com')).called(1);
  });

  test('reloadUser no-op when currentUser is null', () async {
    when(() => mockAuth.currentUser).thenReturn(null);
    await repo.reloadUser();
  });

  test('reloadUser calls user.reload when present', () async {
    final user = MockUser();
    when(() => mockAuth.currentUser).thenReturn(user);
    when(() => user.reload()).thenAnswer((_) async {});
    await repo.reloadUser();
    verify(() => user.reload()).called(1);
  });

  test('sendEmailVerification throws when no user', () async {
    when(() => mockAuth.currentUser).thenReturn(null);
    expect(() => repo.sendEmailVerification(), throwsStateError);
  });
}
