import 'package:fytter/src/domain/workout_entry.dart';

/// Represents a completed workout session, containing all sets performed in that session.
class WorkoutSession {
  /// Unique identifier for this session.
  final String id;

  /// The ID of the workout template this session was based on.
  final String workoutId;

  /// The date and time when the workout session started.
  final DateTime date;

  /// The name of the session (optional, e.g. "Push Day" or "Custom Workout").
  final String? name;

  /// All sets (entries) performed in this session.
  final List<WorkoutEntry> entries;

  /// Optional user notes for this session.
  final String? notes;

  const WorkoutSession({
    required this.id,
    required this.workoutId,
    required this.date,
    required this.entries,
    this.name,
    this.notes,
  });

  /// Convert to JSON for persistence.
  Map<String, dynamic> toJson() => {
        'id': id,
        'workoutId': workoutId,
        'date': date.toIso8601String(),
        'name': name,
        'notes': notes,
        'entries': entries.map((e) => e.toJson()).toList(),
      };

  /// Create from JSON.
  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      id: json['id'] as String,
      workoutId: json['workoutId'] as String,
      date: DateTime.parse(json['date'] as String),
      name: json['name'] as String?,
      notes: json['notes'] as String?,
      entries: (json['entries'] as List)
          .map((e) => WorkoutEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSession &&
          id == other.id &&
          workoutId == other.workoutId &&
          date == other.date &&
          name == other.name &&
          notes == other.notes &&
          _listEquals(entries, other.entries);

  @override
  int get hashCode => Object.hash(
      id,
      workoutId,
      date,
      name,
      notes,
      Object.hashAll(entries),
  );

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() =>
      'WorkoutSession(id: $id, workoutId: $workoutId, date: $date, name: $name, notes: $notes, entries: $entries)';

  WorkoutSession copyWith({
    String? id,
    String? workoutId,
    DateTime? date,
    String? name,
    String? notes,
    List<WorkoutEntry>? entries,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      date: date ?? this.date,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      entries: entries ?? this.entries,
    );
  }
}
