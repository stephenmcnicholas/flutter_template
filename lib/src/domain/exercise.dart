import 'package:flutter/foundation.dart';
import 'exercise_enums.dart';
import 'exercise_input_type.dart';

/// A simple domain model representing a workout exercise.
class Exercise {
  /// Unique identifier for the exercise.
  final String id;

  /// Human-readable name, e.g., "Bench Press".
  final String name;

  /// Optional detailed description.
  final String description;

  /// Optional path to thumbnail image (relative to assets).
  final String? thumbnailPath;

  /// Optional path to full media (image or video, relative to assets).
  final String? mediaPath;

  /// Optional body part targeted by this exercise (e.g., "Chest", "Back", "Quads").
  final String? bodyPart;

  /// Optional equipment used for this exercise (e.g., "Barbell", "Dumbbell", "Machine").
  final String? equipment;

  /// Logging input type (drives reps/weight/time/distance input fields).
  final ExerciseInputType? loggingType;

  // --- AI enrichment fields ---

  /// Primary movement pattern for exercise selection and balance checking.
  final MovementPattern? movementPattern;

  /// Safety tier: 1 = full AI coaching, 2 = limited + disclaimer, 3 = logging only.
  final SafetyTier safetyTier;

  /// Whether bilateral or unilateral; null for cardio / mobility / sport.
  final Laterality? laterality;

  /// How much systemic fatigue this exercise generates.
  final SystemicFatigue systemicFatigue;

  /// Tags: beginner_friendly, home_friendly, low_impact, rehab_safe.
  final List<String> suitability;

  /// ID of the easier regression exercise, if one exists.
  final String? regressionId;

  /// ID of the harder progression exercise, if one exists.
  final String? progressionId;

  const Exercise({
    required this.id,
    required this.name,
    this.description = '',
    this.thumbnailPath,
    this.mediaPath,
    this.bodyPart,
    this.equipment,
    this.loggingType,
    this.movementPattern,
    this.safetyTier = SafetyTier.tier1,
    this.laterality,
    this.systemicFatigue = SystemicFatigue.medium,
    this.suitability = const [],
    this.regressionId,
    this.progressionId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Exercise &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.thumbnailPath == thumbnailPath &&
        other.mediaPath == mediaPath &&
        other.bodyPart == bodyPart &&
        other.equipment == equipment &&
        other.loggingType == loggingType &&
        other.movementPattern == movementPattern &&
        other.safetyTier == safetyTier &&
        other.laterality == laterality &&
        other.systemicFatigue == systemicFatigue &&
        listEquals(other.suitability, suitability) &&
        other.regressionId == regressionId &&
        other.progressionId == progressionId;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        thumbnailPath,
        mediaPath,
        bodyPart,
        equipment,
        loggingType,
        movementPattern,
        safetyTier,
        laterality,
        systemicFatigue,
        Object.hashAll(suitability),
        regressionId,
        progressionId,
      );

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'thumbnailPath': thumbnailPath,
        'mediaPath': mediaPath,
        'bodyPart': bodyPart,
        'equipment': equipment,
        'loggingType':
            loggingType == null ? null : exerciseInputTypeToJson(loggingType!),
        'movementPattern': movementPattern == null
            ? null
            : movementPatternToStorage(movementPattern!),
        'safetyTier': safetyTierToStorage(safetyTier),
        'laterality':
            laterality == null ? null : lateralityToStorage(laterality!),
        'systemicFatigue': systemicFatigueToStorage(systemicFatigue),
        'suitability': suitability.isEmpty ? null : suitability,
        'regressionId': regressionId,
        'progressionId': progressionId,
      };

  /// Create from JSON.
  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      description: (json['description'] as String?) ?? '',
      thumbnailPath: json['thumbnailPath'] as String?,
      mediaPath: json['mediaPath'] as String?,
      bodyPart: json['bodyPart'] as String?,
      equipment: json['equipment'] as String?,
      loggingType: exerciseInputTypeFromJson(json['loggingType'] as String?),
      movementPattern:
          movementPatternFromStorage(json['movementPattern'] as String?),
      safetyTier: safetyTierFromStorage(json['safetyTier'] as int?),
      laterality: lateralityFromStorage(json['laterality'] as String?),
      systemicFatigue:
          systemicFatigueFromStorage(json['systemicFatigue'] as String?),
      suitability: json['suitability'] is List
          ? (json['suitability'] as List).cast<String>()
          : suitabilityFromStorage(json['suitability'] as String?),
      regressionId: json['regressionId'] as String?,
      progressionId: json['progressionId'] as String?,
    );
  }
}
