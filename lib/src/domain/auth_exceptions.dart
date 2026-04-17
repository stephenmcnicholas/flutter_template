class AuthActionCanceled implements Exception {
  final String message;

  const AuthActionCanceled([this.message = 'Sign-in canceled']);

  @override
  String toString() => message;
}

class AuthNotSupported implements Exception {
  final String message;

  const AuthNotSupported([this.message = 'Sign-in not supported on web demo']);

  @override
  String toString() => message;
}
