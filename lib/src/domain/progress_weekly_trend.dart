import 'package:fytter/src/domain/workout_session.dart';

/// Monday 00:00 local for the week containing [date] (date is calendar-local).
DateTime weekStartMonday(DateTime date) {
  final local = DateTime(date.year, date.month, date.day);
  return local.subtract(Duration(days: local.weekday - 1));
}

double sessionVolumeKg(WorkoutSession session) {
  return session.entries.fold<double>(
    0,
    (sum, e) => sum + e.weight * e.reps,
  );
}

class WeeklyTrendBucket {
  final DateTime weekStartMonday;
  final int sessionCount;
  final double volumeKg;

  const WeeklyTrendBucket({
    required this.weekStartMonday,
    required this.sessionCount,
    required this.volumeKg,
  });
}

class WeeklyTrendSeries {
  final List<WeeklyTrendBucket> weeks;

  const WeeklyTrendSeries({required this.weeks});

  bool get isEmpty => weeks.every(
        (w) => w.sessionCount == 0 && w.volumeKg == 0,
      );
}

/// Last [weekCount] weeks, oldest first (index 0). Each week is Mon–Sun local.
///
/// [referenceNow] defaults to [DateTime.now] (local). Tests should pass a fixed
/// value for deterministic buckets.
WeeklyTrendSeries buildWeeklyTrend(
  List<WorkoutSession> sessions, {
  int weekCount = 12,
  DateTime? referenceNow,
}) {
  assert(weekCount > 0);
  final now = referenceNow ?? DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final currentWeekStart = weekStartMonday(today);

  final starts = List<DateTime>.generate(
    weekCount,
    (i) => currentWeekStart.subtract(Duration(days: 7 * (weekCount - 1 - i))),
  );

  final indexForStart = <DateTime, int>{
    for (var i = 0; i < starts.length; i++) starts[i]: i,
  };

  final counts = List<int>.filled(weekCount, 0);
  final volumes = List<double>.filled(weekCount, 0);

  for (final session in sessions) {
    final day = DateTime(
      session.date.year,
      session.date.month,
      session.date.day,
    );
    final ws = weekStartMonday(day);
    final idx = indexForStart[ws];
    if (idx == null) continue;
    counts[idx]++;
    volumes[idx] += sessionVolumeKg(session);
  }

  return WeeklyTrendSeries(
    weeks: List.generate(
      weekCount,
      (i) => WeeklyTrendBucket(
        weekStartMonday: starts[i],
        sessionCount: counts[i],
        volumeKg: volumes[i],
      ),
    ),
  );
}
