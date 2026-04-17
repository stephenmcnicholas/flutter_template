/// Type of check-in interaction.
enum CheckInType {
  preWorkout,
  postSession,
  midProgramme,
  endProgramme,
}

/// Rating given during a check-in.
enum CheckInRating {
  // Pre-workout
  green,
  amber,
  red,
  // Post-session
  great,
  okay,
  tough,
  // Mid-programme
  tooEasy,
  aboutRight,
  tooHard,
}

// ---------------------------------------------------------------------------
// Storage helpers
// ---------------------------------------------------------------------------

const _checkInTypeMap = {
  'pre_workout': CheckInType.preWorkout,
  'post_session': CheckInType.postSession,
  'mid_programme': CheckInType.midProgramme,
  'end_programme': CheckInType.endProgramme,
};

final _checkInTypeToString = _checkInTypeMap.map((k, v) => MapEntry(v, k));

String checkInTypeToStorage(CheckInType value) => _checkInTypeToString[value]!;

CheckInType checkInTypeFromStorage(String value) =>
    _checkInTypeMap[value] ?? CheckInType.postSession;

const _checkInRatingMap = {
  'green': CheckInRating.green,
  'amber': CheckInRating.amber,
  'red': CheckInRating.red,
  'great': CheckInRating.great,
  'okay': CheckInRating.okay,
  'tough': CheckInRating.tough,
  'too_easy': CheckInRating.tooEasy,
  'about_right': CheckInRating.aboutRight,
  'too_hard': CheckInRating.tooHard,
};

final _checkInRatingToString = _checkInRatingMap.map((k, v) => MapEntry(v, k));

String checkInRatingToStorage(CheckInRating value) =>
    _checkInRatingToString[value]!;

CheckInRating checkInRatingFromStorage(String value) =>
    _checkInRatingMap[value] ?? CheckInRating.okay;

/// A single check-in record stored against a session or programme.
class SessionCheckIn {
  final String id;
  final String? sessionId;
  final String? programmeId;
  final CheckInType checkInType;
  final CheckInRating rating;
  final String? freeText;
  final DateTime createdAt;

  const SessionCheckIn({
    required this.id,
    this.sessionId,
    this.programmeId,
    required this.checkInType,
    required this.rating,
    this.freeText,
    required this.createdAt,
  });

  SessionCheckIn copyWith({
    String? id,
    String? sessionId,
    String? programmeId,
    CheckInType? checkInType,
    CheckInRating? rating,
    String? freeText,
    DateTime? createdAt,
  }) {
    return SessionCheckIn(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      programmeId: programmeId ?? this.programmeId,
      checkInType: checkInType ?? this.checkInType,
      rating: rating ?? this.rating,
      freeText: freeText ?? this.freeText,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SessionCheckIn &&
        other.id == id &&
        other.sessionId == sessionId &&
        other.programmeId == programmeId &&
        other.checkInType == checkInType &&
        other.rating == rating &&
        other.freeText == freeText &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        sessionId,
        programmeId,
        checkInType,
        rating,
        freeText,
        createdAt,
      );
}
