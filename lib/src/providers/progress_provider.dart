import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/domain/program.dart';
import 'package:fytter/src/domain/progress_weekly_trend.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/workout_session_provider.dart';
import 'package:fytter/src/utils/shared_prefs.dart';

/// Data class representing exercise progression over time
class ExerciseProgress {
  final String exerciseId;
  final String exerciseName;
  final List<ExerciseSet> sets;
  
  ExerciseProgress({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
  });
}

/// Data class representing a single set in exercise progression
class ExerciseSet {
  final DateTime date;
  final double weight;
  final int reps;
  
  ExerciseSet({
    required this.date,
    required this.weight,
    required this.reps,
  });
}

/// Data class representing workout frequency data
class WorkoutFrequency {
  final Map<DateTime, int> workoutsPerDay; // date -> number of workouts
  final int totalWorkouts;
  final double averageWorkoutsPerWeek;
  
  WorkoutFrequency({
    required this.workoutsPerDay,
    required this.totalWorkouts,
    required this.averageWorkoutsPerWeek,
  });
}

/// Data class representing program statistics
class ProgramStats {
  final int totalPrograms;
  final int completedPrograms;
  final double completionRate;
  final List<ProgramCompletionStat> programCompletionStats;
  
  ProgramStats({
    required this.totalPrograms,
    required this.completedPrograms,
    required this.completionRate,
    required this.programCompletionStats,
  });
}

class ProgramCompletionStat {
  final String programName;
  final DateTime? startDate;
  final int completedCount;
  final int totalCount;

  ProgramCompletionStat({
    required this.programName,
    required this.startDate,
    required this.completedCount,
    required this.totalCount,
  });
}

/// Provider that aggregates exercise progress data from workout history
final exerciseProgressProvider = FutureProvider<List<ExerciseProgress>>((ref) async {
  // Get all exercises and workout sessions
  final exercises = await ref.watch(exercisesFutureProvider.future);
  final sessions = await ref.watch(workoutSessionsProvider.future);
  
  // For each exercise, collect all sets and sort by date
  return exercises.map((exercise) {
    final sets = <ExerciseSet>[];
    
    // Collect all sets for this exercise from all sessions
    for (final session in sessions) {
      for (final entry in session.entries) {
        if (entry.exerciseId == exercise.id) {
          sets.add(ExerciseSet(
            date: session.date,
            weight: entry.weight,
            reps: entry.reps,
          ));
        }
      }
    }
    
    // Sort sets by date
    sets.sort((a, b) => a.date.compareTo(b.date));
    
    return ExerciseProgress(
      exerciseId: exercise.id,
      exerciseName: exercise.name,
      sets: sets,
    );
  }).toList();
});

/// Provider that calculates workout frequency statistics
final workoutFrequencyProvider = FutureProvider<WorkoutFrequency>((ref) async {
  final sessions = await ref.watch(workoutSessionsProvider.future);
  
  // Count workouts per day
  final workoutsPerDay = <DateTime, int>{};
  for (final session in sessions) {
    final date = DateTime(session.date.year, session.date.month, session.date.day);
    workoutsPerDay[date] = (workoutsPerDay[date] ?? 0) + 1;
  }
  
  // Calculate total workouts and average per week
  final totalWorkouts = sessions.length;
  final firstWorkout = sessions.isEmpty ? DateTime.now() : sessions.first.date;
  final lastWorkout = sessions.isEmpty ? DateTime.now() : sessions.last.date;
  final weeksBetween = (lastWorkout.difference(firstWorkout).inDays / 7).ceil();
  final averageWorkoutsPerWeek = weeksBetween == 0 ? 0.0 : totalWorkouts / weeksBetween;
  
  return WorkoutFrequency(
    workoutsPerDay: workoutsPerDay,
    totalWorkouts: totalWorkouts,
    averageWorkoutsPerWeek: averageWorkoutsPerWeek,
  );
});

/// Provider that calculates program statistics
final programStatsProvider = FutureProvider<ProgramStats>((ref) async {
  final programs = await ref.watch(programsFutureProvider.future);

  final sessions = await ref.watch(workoutSessionsProvider.future);

  final sessionCounts = <String, int>{};
  for (final session in sessions) {
    final dayKey = DateTime(session.date.year, session.date.month, session.date.day);
    final key = '${session.workoutId}|${dayKey.toIso8601String()}';
    sessionCounts[key] = (sessionCounts[key] ?? 0) + 1;
  }

  int completedTotal = 0;
  int scheduledTotal = 0;
  final programCompletionStats = <ProgramCompletionStat>[];

  for (final program in programs) {
    int completedForProgram = 0;
    scheduledTotal += program.schedule.length;
    for (final item in program.schedule) {
      final dayKey = DateTime(
        item.scheduledDate.year,
        item.scheduledDate.month,
        item.scheduledDate.day,
      );
      final key = '${item.workoutId}|${dayKey.toIso8601String()}';
      final remaining = sessionCounts[key] ?? 0;
      if (remaining > 0) {
        completedForProgram += 1;
        completedTotal += 1;
        sessionCounts[key] = remaining - 1;
      }
    }
    programCompletionStats.add(
      ProgramCompletionStat(
        programName: program.name,
        startDate: _programStartDate(program),
        completedCount: completedForProgram,
        totalCount: program.schedule.length,
      ),
    );
  }

  final completionRate =
      scheduledTotal == 0 ? 0.0 : completedTotal / scheduledTotal;

  return ProgramStats(
    totalPrograms: programs.length,
    completedPrograms: completedTotal,
    completionRate: completionRate,
    programCompletionStats: programCompletionStats,
  );
}); 

DateTime? _programStartDate(Program program) {
  if (program.schedule.isEmpty) return null;
  final sorted = [...program.schedule]
    ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
  return sorted.first.scheduledDate;
}

// ---------------------------------------------------------------------------
// Progress tab — weekly trend (§4.3)
// ---------------------------------------------------------------------------

/// Default number of Monday-start weeks shown on the Progress chart.
const int kProgressWeeklyTrendWeekCount = 12;

enum ProgressWeeklyMetric { sessions, volume }

final weeklyTrendProvider = FutureProvider<WeeklyTrendSeries>((ref) async {
  final sessions = await ref.watch(workoutSessionsProvider.future);
  return buildWeeklyTrend(
    sessions,
    weekCount: kProgressWeeklyTrendWeekCount,
  );
});

class ProgressWeeklyMetricNotifier extends StateNotifier<ProgressWeeklyMetric> {
  ProgressWeeklyMetricNotifier() : super(ProgressWeeklyMetric.sessions) {
    _load();
  }

  static const _prefsKey = 'progressWeeklyTrendMetric';

  Future<void> _load() async {
    final raw = await SharedPrefs.instance.getString(_prefsKey);
    if (raw == ProgressWeeklyMetric.volume.name) {
      state = ProgressWeeklyMetric.volume;
    }
  }

  Future<void> setMetric(ProgressWeeklyMetric metric) async {
    state = metric;
    await SharedPrefs.instance.setString(_prefsKey, metric.name);
  }
}

final progressWeeklyMetricProvider =
    StateNotifierProvider<ProgressWeeklyMetricNotifier, ProgressWeeklyMetric>(
        (ref) {
  return ProgressWeeklyMetricNotifier();
});