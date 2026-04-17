import 'package:fytter/src/domain/program.dart';
import 'package:fytter/src/domain/workout_session.dart';

enum ProgramWorkoutStatus { planned, completed, missed }

DateTime normalizeProgramDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

String programWorkoutKey(String workoutId, DateTime date) {
  return '$workoutId|${normalizeProgramDate(date).toIso8601String()}';
}

Set<String> programCompletionKeysFromSessions(List<WorkoutSession> sessions) {
  final keys = <String>{};
  for (final session in sessions) {
    keys.add(programWorkoutKey(session.workoutId, session.date));
  }
  return keys;
}

/// Count of logged sessions whose [WorkoutSession.workoutId] appears on [program]'s schedule.
int countSessionsForProgramSchedule(Program program, List<WorkoutSession> sessions) {
  final ids = program.schedule.map((pw) => pw.workoutId).toSet();
  if (ids.isEmpty) return 0;
  return sessions.where((s) => ids.contains(s.workoutId)).length;
}

/// Milestone index for mid-programme check-in: `1` = 6th matching session, `2` = 12th, etc.
/// Returns null when no check-in is due for the current count.
int? midProgrammeMilestoneForSessionCount(int sessionsMatchingProgramTemplates) {
  if (sessionsMatchingProgramTemplates <= 0) return null;
  if (sessionsMatchingProgramTemplates % 6 != 0) return null;
  return sessionsMatchingProgramTemplates ~/ 6;
}

/// True when every slot on [program.schedule] is logged as completed.
bool isProgramScheduleFullyCompleted(
  Program program,
  Map<String, ProgramWorkoutStatus> statusByKey,
) {
  if (program.schedule.isEmpty) return false;
  for (final w in program.schedule) {
    final key = programWorkoutKey(w.workoutId, w.scheduledDate);
    if (statusByKey[key] != ProgramWorkoutStatus.completed) {
      return false;
    }
  }
  return true;
}

/// Aggregates logged sessions whose template id appears on the programme schedule.
({int sessionCount, double totalVolumeKg, int totalSets}) programmeLoggedStats(
  Program program,
  List<WorkoutSession> sessions,
) {
  final ids = program.schedule.map((pw) => pw.workoutId).toSet();
  if (ids.isEmpty) {
    return (sessionCount: 0, totalVolumeKg: 0.0, totalSets: 0);
  }
  var count = 0;
  var volume = 0.0;
  var sets = 0;
  for (final s in sessions) {
    if (!ids.contains(s.workoutId)) continue;
    count++;
    for (final e in s.entries) {
      volume += e.weight * e.reps;
      sets++;
    }
  }
  return (sessionCount: count, totalVolumeKg: volume, totalSets: sets);
}

ProgramWorkoutStatus programWorkoutStatus(
  ProgramWorkout workout,
  Set<String> completedKeys,
  DateTime now,
) {
  final key = programWorkoutKey(workout.workoutId, workout.scheduledDate);
  if (completedKeys.contains(key)) {
    return ProgramWorkoutStatus.completed;
  }
  final today = normalizeProgramDate(now);
  final date = normalizeProgramDate(workout.scheduledDate);
  if (date.isBefore(today)) {
    return ProgramWorkoutStatus.missed;
  }
  return ProgramWorkoutStatus.planned;
}

Map<String, ProgramWorkoutStatus> programStatusByKey(
  List<ProgramWorkout> schedule,
  Set<String> completedKeys,
  DateTime now,
) {
  final map = <String, ProgramWorkoutStatus>{};
  for (final item in schedule) {
    map[programWorkoutKey(item.workoutId, item.scheduledDate)] =
        programWorkoutStatus(item, completedKeys, now);
  }
  return map;
}

List<ProgramWorkout> updateProgramWorkoutDateAtIndex(
  List<ProgramWorkout> schedule,
  int index,
  DateTime newDate,
) {
  if (index < 0 || index >= schedule.length) return schedule;
  final normalized = normalizeProgramDate(newDate);
  return [
    for (var i = 0; i < schedule.length; i++)
      if (i == index)
        ProgramWorkout(
          workoutId: schedule[i].workoutId,
          scheduledDate: normalized,
        )
      else
        schedule[i],
  ];
}

List<ProgramWorkout> shiftProgramScheduleByOffset(
  List<ProgramWorkout> schedule,
  int offsetDays,
) {
  if (offsetDays == 0) return schedule;
  return [
    for (final item in schedule)
      ProgramWorkout(
        workoutId: item.workoutId,
        scheduledDate:
            normalizeProgramDate(item.scheduledDate).add(Duration(days: offsetDays)),
      ),
  ];
}

List<ProgramWorkout> shiftProgramScheduleToNewStart(
  List<ProgramWorkout> schedule,
  DateTime newStartDate,
) {
  if (schedule.isEmpty) return schedule;
  final sorted = [...schedule]
    ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
  final originalStart = normalizeProgramDate(sorted.first.scheduledDate);
  final newStart = normalizeProgramDate(newStartDate);
  final offsetDays = newStart.difference(originalStart).inDays;
  return shiftProgramScheduleByOffset(schedule, offsetDays);
}

List<ProgramWorkout> shiftProgramScheduleByEditingIndex(
  List<ProgramWorkout> schedule,
  int index,
  DateTime newDate,
) {
  if (index < 0 || index >= schedule.length) return schedule;
  final original = normalizeProgramDate(schedule[index].scheduledDate);
  final target = normalizeProgramDate(newDate);
  final offsetDays = target.difference(original).inDays;
  if (offsetDays == 0) return schedule;
  return [
    for (final item in schedule)
      if (normalizeProgramDate(item.scheduledDate).isBefore(original))
        item
      else
        ProgramWorkout(
          workoutId: item.workoutId,
          scheduledDate:
              normalizeProgramDate(item.scheduledDate).add(Duration(days: offsetDays)),
        ),
  ];
}

int indexOfEarliestProgramWorkout(List<ProgramWorkout> schedule) {
  if (schedule.isEmpty) return -1;
  var earliestIndex = 0;
  var earliest = normalizeProgramDate(schedule[0].scheduledDate);
  for (var i = 1; i < schedule.length; i++) {
    final current = normalizeProgramDate(schedule[i].scheduledDate);
    if (current.isBefore(earliest)) {
      earliest = current;
      earliestIndex = i;
    }
  }
  return earliestIndex;
}
