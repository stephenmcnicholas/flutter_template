import 'package:fytter/src/domain/workout_entry.dart';

class Workout {
  final String id;
  final String name;
  final List<WorkoutEntry> entries; // Prescribed sets/reps/load for each exercise

  const Workout({
    required this.id,
    required this.name,
    this.entries = const [],
  });

  // JSON serialization (optional):
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'entries': entries.map((e) => e.toJson()).toList(),
      };

  factory Workout.fromJson(Map<String, dynamic> json) => Workout(
        id: json['id'] as String,
        name: json['name'] as String,
        entries: (json['entries'] as List<dynamic>? ?? [])
            .map((e) => WorkoutEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Workout &&
          other.id == id &&
          other.name == name &&
          _listEquals(other.entries, entries);

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ _listHashCode(entries);

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static int _listHashCode<T>(List<T> items) {
    return items.fold(0, (prev, e) => prev ^ e.hashCode);
  }
}