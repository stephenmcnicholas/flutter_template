/// Movement pattern classification for exercise selection and balance checking.
enum MovementPattern {
  pushHorizontal,
  pushVertical,
  pullHorizontal,
  pullVertical,
  squat,
  hinge,
  lunge,
  carry,
  rotation,
  isolationUpper,
  isolationLower,
  cardio,
  /// Warm-up / prep patterns (spinal, hip, shoulder, etc.); includes static stretches.
  mobility,
  /// Anti-rotation / anti-extension / trunk work not classified as rotation.
  core,
  /// Scheduled activities (tennis, pilates, etc.) — log-only / specialist domain.
  sport,
}

/// Safety tier for AI coaching level.
/// Tier 1: full AI coaching. Tier 2: limited + disclaimer. Tier 3: logging only.
enum SafetyTier { tier1, tier2, tier3 }

/// Whether an exercise is bilateral or unilateral.
enum Laterality { bilateral, unilateral }

/// How much systemic fatigue an exercise generates.
enum SystemicFatigue { high, medium, low }

// ---------------------------------------------------------------------------
// Storage helpers (same pattern as user_profile.dart)
// ---------------------------------------------------------------------------

const _movementPatternMap = {
  'push_horizontal': MovementPattern.pushHorizontal,
  'push_vertical': MovementPattern.pushVertical,
  'pull_horizontal': MovementPattern.pullHorizontal,
  'pull_vertical': MovementPattern.pullVertical,
  'squat': MovementPattern.squat,
  'hinge': MovementPattern.hinge,
  'lunge': MovementPattern.lunge,
  'carry': MovementPattern.carry,
  'rotation': MovementPattern.rotation,
  'isolation_upper': MovementPattern.isolationUpper,
  'isolation_lower': MovementPattern.isolationLower,
  'cardio': MovementPattern.cardio,
  'mobility': MovementPattern.mobility,
  'core': MovementPattern.core,
  'sport': MovementPattern.sport,
};

final _movementPatternToString =
    _movementPatternMap.map((k, v) => MapEntry(v, k));

String movementPatternToStorage(MovementPattern value) =>
    _movementPatternToString[value]!;

MovementPattern? movementPatternFromStorage(String? value) {
  if (value == null) return null;
  return _movementPatternMap[value];
}

int safetyTierToStorage(SafetyTier value) {
  switch (value) {
    case SafetyTier.tier1:
      return 1;
    case SafetyTier.tier2:
      return 2;
    case SafetyTier.tier3:
      return 3;
  }
}

SafetyTier safetyTierFromStorage(int? value) {
  switch (value) {
    case 2:
      return SafetyTier.tier2;
    case 3:
      return SafetyTier.tier3;
    default:
      return SafetyTier.tier1;
  }
}

String lateralityToStorage(Laterality value) {
  switch (value) {
    case Laterality.bilateral:
      return 'bilateral';
    case Laterality.unilateral:
      return 'unilateral';
  }
}

Laterality? lateralityFromStorage(String? value) {
  switch (value) {
    case 'bilateral':
      return Laterality.bilateral;
    case 'unilateral':
      return Laterality.unilateral;
    default:
      return null;
  }
}

String systemicFatigueToStorage(SystemicFatigue value) {
  switch (value) {
    case SystemicFatigue.high:
      return 'high';
    case SystemicFatigue.medium:
      return 'medium';
    case SystemicFatigue.low:
      return 'low';
  }
}

SystemicFatigue systemicFatigueFromStorage(String? value) {
  switch (value) {
    case 'high':
      return SystemicFatigue.high;
    case 'low':
      return SystemicFatigue.low;
    default:
      return SystemicFatigue.medium;
  }
}

List<String> suitabilityFromStorage(String? value) {
  if (value == null || value.isEmpty) return [];
  return value.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
}

String? suitabilityToStorage(List<String>? value) {
  if (value == null || value.isEmpty) return null;
  return value.join(',');
}
