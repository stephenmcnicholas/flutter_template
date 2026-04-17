/// Estimates workout duration in minutes for the "Let's go" screen.
/// Uses work time (total sets × 0.5 min) + rest between sets (user's preferred
/// rest or default 2 min). Clamped to 15–90 min per DECISIONS.md.
int estimateWorkoutDurationMinutes({
  required Map<String, List<Map<String, dynamic>>>? initialSetsByExercise,
  required int restSeconds,
}) {
  int totalSets = 0;
  if (initialSetsByExercise != null && initialSetsByExercise.isNotEmpty) {
    for (final sets in initialSetsByExercise.values) {
      totalSets += sets.length;
    }
  }
  if (totalSets == 0) return 30; // fallback when no prescribed sets

  const workMinutesPerSet = 0.5; // 30 seconds per set
  final workMinutes = totalSets * workMinutesPerSet;
  final restPeriods = (totalSets - 1).clamp(0, 999);
  final restMinutes = restPeriods * (restSeconds / 60.0);

  final total = workMinutes + restMinutes;
  return total.round().clamp(15, 90);
}
