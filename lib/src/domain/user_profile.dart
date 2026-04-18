/// Generic user profile entity.
///
/// Extend this with app-specific fields when building a concrete app on top
/// of this template.
class UserProfile {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final DateTime createdAt;

  const UserProfile({
    required this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
    required this.createdAt,
  });

  UserProfile copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? photoUrl,
    DateTime? createdAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
