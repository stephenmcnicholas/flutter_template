import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/data/auth_repository_factory.dart';
import 'package:fytter/src/domain/auth_exceptions.dart';
import 'package:fytter/src/domain/auth_repository.dart';
import 'package:fytter/src/domain/auth_user.dart';

enum AuthStatus {
  signedOut,
  signedInUnverified,
  signedInVerified,
}

class AuthControllerState {
  final bool isLoading;
  final String? errorMessage;

  const AuthControllerState({
    this.isLoading = false,
    this.errorMessage,
  });

  AuthControllerState copyWith({
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthControllerState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthController extends StateNotifier<AuthControllerState> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(const AuthControllerState());

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _perform(() => _repository.signInWithEmail(
      email: email,
      password: password,
    ));
  }

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
  }) {
    return _perform(() => _repository.signUpWithEmail(
      email: email,
      password: password,
    ));
  }

  Future<bool> signInWithGoogle() {
    return _perform(_repository.signInWithGoogle);
  }

  Future<bool> sendPasswordReset({required String email}) {
    return _perform(() => _repository.sendPasswordReset(email: email));
  }

  Future<bool> resendEmailVerification() {
    return _perform(_repository.sendEmailVerification);
  }

  Future<bool> refreshUser() {
    return _perform(_repository.reloadUser);
  }

  Future<bool> signOut() {
    return _perform(_repository.signOut);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  Future<bool> _perform(Future<void> Function() action) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await action();
      state = state.copyWith(isLoading: false, errorMessage: null);
      return true;
    } catch (error) {
      if (error is AuthActionCanceled) {
        state = state.copyWith(isLoading: false, errorMessage: null);
        return false;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: _mapError(error),
      );
      return false;
    }
  }

  String _mapError(Object error) {
    if (error is AuthNotSupported) {
      return error.message;
    }
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Enter a valid email address.';
        case 'user-not-found':
          return 'No account found for that email.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'email-already-in-use':
          return 'That email is already in use.';
        case 'weak-password':
          return 'Password should be at least 6 characters.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many attempts. Try again later.';
        case 'network-request-failed':
          return 'Network error. Check your connection.';
        case 'operation-not-allowed':
          return 'Sign-in method not enabled yet.';
        case 'account-exists-with-different-credential':
          return 'Use the provider linked to this email.';
        default:
          return error.message ?? 'Something went wrong. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return createAuthRepository();
});

final authUserProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final authStatusProvider = Provider<AuthStatus>((ref) {
  final user = ref.watch(authUserProvider).maybeWhen(
        data: (user) => user,
        orElse: () => null,
      );
  if (user == null) return AuthStatus.signedOut;
  return user.isEmailVerified
      ? AuthStatus.signedInVerified
      : AuthStatus.signedInUnverified;
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthControllerState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthController(repository);
});
