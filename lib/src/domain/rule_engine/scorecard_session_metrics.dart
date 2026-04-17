import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/exercise_enums.dart';
import 'package:fytter/src/domain/program.dart';
import 'package:fytter/src/domain/workout_session.dart';

/// Calendar day in local time (scorecard / adherence windows).
DateTime scorecardDateOnlyLocal(DateTime d) {
  final l = d.toLocal();
  return DateTime(l.year, l.month, l.day);
}

/// Sessions whose local calendar day falls in \[[start], [today]\] inclusive.
int scorecardCountSessionsInRollingDayWindow(
  Iterable<WorkoutSession> sessions,
  DateTime now, {
  int days = 28,
}) {
  final today = scorecardDateOnlyLocal(now);
  final start = today.subtract(Duration(days: days));
  var n = 0;
  for (final s in sessions) {
    final d = scorecardDateOnlyLocal(s.date);
    if (!d.isBefore(start) && !d.isAfter(today)) n++;
  }
  return n;
}

/// Scheduled programme slots in the same rolling local-day window (inclusive).
int scorecardCountScheduledSlotsInRollingDayWindow(
  Iterable<Program> programs,
  DateTime now, {
  int days = 28,
}) {
  final today = scorecardDateOnlyLocal(now);
  final start = today.subtract(Duration(days: days));
  var n = 0;
  for (final p in programs) {
    for (final pw in p.schedule) {
      final d = scorecardDateOnlyLocal(pw.scheduledDate);
      if (!d.isBefore(start) && !d.isAfter(today)) n++;
    }
  }
  return n;
}

/// Movement pattern storage keys covered by [exerciseIds] given [catalog].
Set<String> scorecardMovementPatternKeysForExerciseIds(
  Set<String> exerciseIds,
  List<Exercise> catalog,
) {
  final byId = {for (final e in catalog) e.id: e};
  final out = <String>{};
  for (final id in exerciseIds) {
    final e = byId[id];
    final p = e?.movementPattern;
    if (p != null) out.add(movementPatternToStorage(p));
  }
  return out;
}

/// All non-null movement patterns in the exercise catalog.
Set<String> scorecardAllMovementPatternKeys(List<Exercise> catalog) {
  final out = <String>{};
  for (final e in catalog) {
    final p = e.movementPattern;
    if (p != null) out.add(movementPatternToStorage(p));
  }
  return out;
}

/// Collect exercise ids from the last [maxSessions] sessions (most recent first list).
Set<String> scorecardRecentExerciseIds(
  List<WorkoutSession> sessionsNewestFirst, {
  int maxSessions = 12,
}) {
  final out = <String>{};
  final slice = sessionsNewestFirst.take(maxSessions);
  for (final s in slice) {
    for (final e in s.entries) {
      out.add(e.exerciseId);
    }
  }
  return out;
}

/// Nearest scheduled row for [session.workoutId] within [maxDayDistance] of [session.date], if any.
ProgramWorkout? scorecardNearestScheduledWorkout(
  Program program,
  WorkoutSession session, {
  int maxDayDistance = 4,
}) {
  if (session.workoutId.isEmpty) return null;
  ProgramWorkout? best;
  var bestAbs = maxDayDistance + 1;
  for (final pw in program.schedule) {
    if (pw.workoutId != session.workoutId) continue;
    final abs = (pw.scheduledDate.difference(session.date).inDays).abs();
    if (abs < bestAbs) {
      bestAbs = abs;
      best = pw;
    }
  }
  if (best == null || bestAbs > maxDayDistance) return null;
  return best;
}

/// True if the session local day is on or before the scheduled local day for [nearest].
bool scorecardTrainedOnOrBeforeScheduledDay(
  WorkoutSession session,
  ProgramWorkout nearest,
) {
  final ds = scorecardDateOnlyLocal(session.date);
  final dp = scorecardDateOnlyLocal(nearest.scheduledDate);
  return !ds.isAfter(dp);
}
