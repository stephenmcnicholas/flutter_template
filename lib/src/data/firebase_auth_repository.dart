import 'package:firebase_auth/firebase_auth.dart';
import 'package:fytter/src/domain/auth_repository.dart';
import 'package:fytter/src/domain/auth_user.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  bool _googleInitialized = false;

  FirebaseAuthRepository({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  @override
  Stream<AuthUser?> authStateChanges() {
    return _auth.userChanges().map(_mapUser);
  }

  @override
  AuthUser? currentUser() => _mapUser(_auth.currentUser);

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _requireUser(credential.user);
  }

  @override
  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = _requireUser(credential.user);
    if (!user.isEmailVerified) {
      await _auth.currentUser?.sendEmailVerification();
    }
    return user;
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    await _ensureGoogleInitialized();
    final googleUser = await _googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    return _requireUser(userCredential.user);
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in user.');
    }
    await user.sendEmailVerification();
  }

  @override
  Future<void> reloadUser() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.reload();
  }

  @override
  Future<void> sendPasswordReset({required String email}) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> signOut() async {
    await _ensureGoogleInitialized();
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  AuthUser _requireUser(User? user) {
    final mapped = _mapUser(user);
    if (mapped == null) {
      throw StateError('Authentication failed.');
    }
    return mapped;
  }

  AuthUser? _mapUser(User? user) {
    if (user == null) return null;
    return AuthUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      isEmailVerified: user.emailVerified,
    );
  }

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await _googleSignIn.initialize();
    _googleInitialized = true;
  }
}
