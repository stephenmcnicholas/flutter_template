class AuthUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool isEmailVerified;

  const AuthUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.isEmailVerified,
  });
}
