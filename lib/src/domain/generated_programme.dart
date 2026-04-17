/// DTO matching the Cloud Function / LLM programme output schema.
/// Used by the rule-based builder and when parsing the generateProgram response.
library;

/// A single set prescription: reps and optional load.
class GeneratedProgrammeSet {
  final int reps;
  final double? targetLoadKg;

  const GeneratedProgrammeSet({required this.reps, this.targetLoadKg});

  Map<String, dynamic> toJson() => {
        'reps': reps,
        if (targetLoadKg != null) 'targetLoadKg': targetLoadKg,
      };

  static GeneratedProgrammeSet fromJson(Map<String, dynamic> json) {
    return GeneratedProgrammeSet(
      reps: (json['reps'] as num?)?.toInt() ?? 8,
      targetLoadKg: (json['targetLoadKg'] as num?)?.toDouble(),
    );
  }
}

class GeneratedProgrammeExercise {
  final String exerciseId;
  /// One entry per set. Straight sets will have identical values; pyramid/drop sets vary.
  final List<GeneratedProgrammeSet> sets;
  final int? restSeconds;
  final String? coachingNote;

  const GeneratedProgrammeExercise({
    required this.exerciseId,
    required this.sets,
    this.restSeconds,
    this.coachingNote,
  });

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'sets': sets.map((s) => s.toJson()).toList(),
        if (restSeconds != null) 'restSeconds': restSeconds,
        if (coachingNote != null) 'coachingNote': coachingNote,
      };

  static GeneratedProgrammeExercise fromJson(Map<String, dynamic> json) {
    final rawSets = json['sets'];
    final List<GeneratedProgrammeSet> sets;
    if (rawSets is List) {
      // New format: array of { reps, targetLoadKg? }
      sets = rawSets
          .map((s) => GeneratedProgrammeSet.fromJson(s as Map<String, dynamic>))
          .toList();
    } else {
      // Legacy flat format: sets: number, reps: number, targetLoadKg: number
      final setCount = (rawSets as num?)?.toInt() ?? 3;
      final reps = (json['reps'] as num?)?.toInt() ?? 8;
      final load = (json['targetLoadKg'] as num?)?.toDouble();
      sets = List.generate(setCount, (_) => GeneratedProgrammeSet(reps: reps, targetLoadKg: load));
    }
    return GeneratedProgrammeExercise(
      exerciseId: json['exerciseId'] as String,
      sets: sets.isEmpty
          ? [const GeneratedProgrammeSet(reps: 8)]
          : sets,
      restSeconds: (json['restSeconds'] as num?)?.toInt(),
      coachingNote: json['coachingNote'] as String?,
    );
  }
}

class GeneratedProgrammeWorkout {
  final String dayOfWeek;
  final String workoutName;
  final String? briefDescription;
  final List<GeneratedProgrammeExercise> exercises;

  const GeneratedProgrammeWorkout({
    required this.dayOfWeek,
    required this.workoutName,
    this.briefDescription,
    required this.exercises,
  });

  Map<String, dynamic> toJson() => {
        'dayOfWeek': dayOfWeek,
        'workoutName': workoutName,
        if (briefDescription != null) 'briefDescription': briefDescription,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  static GeneratedProgrammeWorkout fromJson(Map<String, dynamic> json) {
    final exercisesList = json['exercises'] as List<dynamic>? ?? [];
    return GeneratedProgrammeWorkout(
      dayOfWeek: (json['dayOfWeek'] as String?) ?? 'monday',
      workoutName: (json['workoutName'] as String?) ?? 'Workout',
      briefDescription: json['briefDescription'] as String?,
      exercises: exercisesList
          .map((e) => GeneratedProgrammeExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class GeneratedProgrammeDeload {
  final String when;
  final String guidance;

  const GeneratedProgrammeDeload({required this.when, required this.guidance});

  Map<String, dynamic> toJson() => {'when': when, 'guidance': guidance};

  static GeneratedProgrammeDeload? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final when = json['when'] as String?;
    final guidance = json['guidance'] as String?;
    if (when == null || guidance == null) return null;
    return GeneratedProgrammeDeload(when: when, guidance: guidance);
  }
}

class GeneratedProgramme {
  final String programmeName;
  final String programmeDescription;
  final String? coachIntro;
  final String? coachRationale;
  final String? coachRationaleSpoken;
  final int durationWeeks;
  final List<String> personalisationNotes;
  final List<GeneratedProgrammeWorkout> workouts;
  final GeneratedProgrammeDeload? deloadWeek;
  final String? weeklyProgression;

  const GeneratedProgramme({
    required this.programmeName,
    required this.programmeDescription,
    this.coachIntro,
    this.coachRationale,
    this.coachRationaleSpoken,
    required this.durationWeeks,
    this.personalisationNotes = const [],
    required this.workouts,
    this.deloadWeek,
    this.weeklyProgression,
  });

  Map<String, dynamic> toJson() => {
        'programmeName': programmeName,
        'programmeDescription': programmeDescription,
        if (coachIntro != null) 'coachIntro': coachIntro,
        if (coachRationale != null) 'coachRationale': coachRationale,
        if (coachRationaleSpoken != null) 'coachRationaleSpoken': coachRationaleSpoken,
        'durationWeeks': durationWeeks,
        'personalisationNotes': personalisationNotes,
        'workouts': workouts.map((w) => w.toJson()).toList(),
        if (deloadWeek != null) 'deloadWeek': deloadWeek!.toJson(),
        if (weeklyProgression != null) 'weeklyProgression': weeklyProgression,
      };

  static GeneratedProgramme fromJson(Map<String, dynamic> json) {
    final workoutsList = json['workouts'] as List<dynamic>? ?? [];
    final notesList = json['personalisationNotes'] as List<dynamic>? ?? [];
    return GeneratedProgramme(
      programmeName: (json['programmeName'] as String?) ?? 'Generated Programme',
      programmeDescription:
          (json['programmeDescription'] as String?) ?? 'Rule-built programme.',
      coachIntro: json['coachIntro'] as String?,
      coachRationale: json['coachRationale'] as String?,
      coachRationaleSpoken: json['coachRationaleSpoken'] as String?,
      durationWeeks: (json['durationWeeks'] as num?)?.toInt() ?? 4,
      personalisationNotes: notesList
          .map((e) => e.toString())
          .where((s) => s.isNotEmpty)
          .toList(),
      workouts: workoutsList
          .map((w) => GeneratedProgrammeWorkout.fromJson(w as Map<String, dynamic>))
          .toList(),
      deloadWeek: GeneratedProgrammeDeload.fromJson(
          json['deloadWeek'] as Map<String, dynamic>?),
      weeklyProgression: json['weeklyProgression'] as String?,
    );
  }
}
