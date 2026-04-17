/// A domain model representing a scheduled instance of a program.
class ScheduledProgram {
  /// Unique identifier for this scheduled program.
  final String id;

  /// The ID of the program template being scheduled.
  final String programId;

  /// The date this program is scheduled for (local date, no time).
  final DateTime date;

  /// Optional user notes for this scheduled program.
  final String? notes;

  const ScheduledProgram({
    required this.id,
    required this.programId,
    required this.date,
    this.notes,
  });

  /// Convert to JSON for persistence.
  Map<String, dynamic> toJson() => {
        'id': id,
        'programId': programId,
        'date': date.toIso8601String(),
        'notes': notes,
      };

  /// Create from JSON.
  factory ScheduledProgram.fromJson(Map<String, dynamic> json) {
    return ScheduledProgram(
      id: json['id'] as String,
      programId: json['programId'] as String,
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScheduledProgram &&
        other.id == id &&
        other.programId == programId &&
        other.date == date &&
        other.notes == notes;
  }

  @override
  int get hashCode => Object.hash(id, programId, date, notes);
} 