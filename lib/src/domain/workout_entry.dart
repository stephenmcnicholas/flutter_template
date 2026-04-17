/// A domain model for a single set, used in both templates and records.
class WorkoutEntry {
  /// Unique identifier for this entry.
  final String id;

  /// The exercise this entry logs.
  final String exerciseId;

  /// Number of repetitions (prescribed or actual).
  final int reps;

  /// Weight lifted (prescribed or actual, in kilograms by default).
  final double weight;

  /// Distance covered (in kilometers, for cardio exercises).
  final double? distance;

  /// Duration of exercise (in seconds, for time-based exercises).
  final int? duration;

  /// Timestamp when this set was recorded (nullable for templates).
  final DateTime? timestamp;

  /// The session this entry belongs to (nullable for legacy entries).
  final String? sessionId;

  /// Indicates whether this entry is complete.
  final bool isComplete;

  /// Outcome of this set: 'completed', 'failed', 'skipped', or null for legacy data.
  final String? setOutcome;

  /// Optional superset group id; entries with the same id belong to the same superset within a workout.
  final String? supersetGroupId;

  const WorkoutEntry({
    required this.id,
    required this.exerciseId,
    required this.reps,
    required this.weight,
    this.distance,
    this.duration,
    this.timestamp,
    this.sessionId,
    required this.isComplete,
    this.setOutcome,
    this.supersetGroupId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutEntry &&
        other.id == id &&
        other.exerciseId == exerciseId &&
        other.reps == reps &&
        other.weight == weight &&
        other.distance == distance &&
        other.duration == duration &&
        other.timestamp == timestamp &&
        other.sessionId == sessionId &&
        other.isComplete == isComplete &&
        other.setOutcome == setOutcome &&
        other.supersetGroupId == supersetGroupId;
  }

  @override
  int get hashCode => Object.hash(id, exerciseId, reps, weight, distance,
      duration, timestamp, sessionId, isComplete, setOutcome, supersetGroupId);

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'exerciseId': exerciseId,
        'reps': reps,
        'weight': weight,
        if (distance != null) 'distance': distance,
        if (duration != null) 'duration': duration,
        'isComplete': isComplete,
        if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
        if (sessionId != null) 'sessionId': sessionId,
        if (setOutcome != null) 'setOutcome': setOutcome,
        if (supersetGroupId != null) 'supersetGroupId': supersetGroupId,
      };

  /// Create from JSON.
  factory WorkoutEntry.fromJson(Map<String, dynamic> json) {
    return WorkoutEntry(
      id: json['id'] as String,
      exerciseId: json['exerciseId'] as String,
      reps: json['reps'] as int,
      weight: (json['weight'] as num).toDouble(),
      distance: json['distance'] != null ? (json['distance'] as num).toDouble() : null,
      duration: json['duration'] != null ? json['duration'] as int : null,
      isComplete: json['isComplete'] as bool? ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
      sessionId: json['sessionId'] as String?,
      setOutcome: json['setOutcome'] as String?,
      supersetGroupId: json['supersetGroupId'] as String?,
    );
  }

  @override
  String toString() =>
      'WorkoutEntry(id: $id, exerciseId: $exerciseId, reps: $reps, weight: $weight, distance: $distance, duration: $duration, isComplete: $isComplete, timestamp: $timestamp, sessionId: $sessionId, setOutcome: $setOutcome, supersetGroupId: $supersetGroupId)';
}