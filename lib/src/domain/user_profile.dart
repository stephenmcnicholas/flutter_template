/// Primary goal for training (maps to program generation).
enum PrimaryGoal {
  getStronger,
  buildMuscle,
  loseFat,
  generalFitness,
}

/// Equipment access (maps to exercise filtering).
enum EquipmentAccess {
  homeDumbbells,
  fullGym,
  bodyweightOnly,
}

/// Self-reported experience level (affects tone and progression).
enum ExperienceLevel {
  never,
  some,
  regular,
}

/// String values for persistence (match design doc).
const String kPrimaryGoalGetStronger = 'get_stronger';
const String kPrimaryGoalBuildMuscle = 'build_muscle';
const String kPrimaryGoalLoseFat = 'lose_fat';
const String kPrimaryGoalGeneralFitness = 'general_fitness';
const String kEquipmentHomeDumbbells = 'home_dumbbells';
const String kEquipmentFullGym = 'full_gym';
const String kEquipmentBodyweightOnly = 'bodyweight_only';
const String kExperienceNever = 'never';
const String kExperienceSome = 'some';
const String kExperienceRegular = 'regular';

/// Default values when user skips onboarding steps.
const String kDefaultPrimaryGoal = kPrimaryGoalGeneralFitness;
const int kDefaultDaysPerWeek = 3;
const int kDefaultSessionLengthMinutes = 60;
const String kDefaultEquipment = kEquipmentFullGym;
const String kDefaultExperienceLevel = kExperienceNever;

String primaryGoalToStorage(PrimaryGoal goal) {
  switch (goal) {
    case PrimaryGoal.getStronger:
      return kPrimaryGoalGetStronger;
    case PrimaryGoal.buildMuscle:
      return kPrimaryGoalBuildMuscle;
    case PrimaryGoal.loseFat:
      return kPrimaryGoalLoseFat;
    case PrimaryGoal.generalFitness:
      return kPrimaryGoalGeneralFitness;
  }
}

PrimaryGoal primaryGoalFromStorage(String? value) {
  switch (value) {
    case kPrimaryGoalGetStronger:
      return PrimaryGoal.getStronger;
    case kPrimaryGoalBuildMuscle:
      return PrimaryGoal.buildMuscle;
    case kPrimaryGoalLoseFat:
      return PrimaryGoal.loseFat;
    case kPrimaryGoalGeneralFitness:
    default:
      return PrimaryGoal.generalFitness;
  }
}

String equipmentToStorage(EquipmentAccess equipment) {
  switch (equipment) {
    case EquipmentAccess.homeDumbbells:
      return kEquipmentHomeDumbbells;
    case EquipmentAccess.fullGym:
      return kEquipmentFullGym;
    case EquipmentAccess.bodyweightOnly:
      return kEquipmentBodyweightOnly;
  }
}

EquipmentAccess equipmentFromStorage(String? value) {
  switch (value) {
    case kEquipmentHomeDumbbells:
      return EquipmentAccess.homeDumbbells;
    case kEquipmentFullGym:
      return EquipmentAccess.fullGym;
    case kEquipmentBodyweightOnly:
      return EquipmentAccess.bodyweightOnly;
    default:
      return EquipmentAccess.fullGym;
  }
}

String experienceLevelToStorage(ExperienceLevel level) {
  switch (level) {
    case ExperienceLevel.never:
      return kExperienceNever;
    case ExperienceLevel.some:
      return kExperienceSome;
    case ExperienceLevel.regular:
      return kExperienceRegular;
  }
}

ExperienceLevel experienceLevelFromStorage(String? value) {
  switch (value) {
    case kExperienceNever:
      return ExperienceLevel.never;
    case kExperienceSome:
      return ExperienceLevel.some;
    case kExperienceRegular:
      return ExperienceLevel.regular;
    default:
      return ExperienceLevel.never;
  }
}

/// User profile for onboarding and AI program generation (single source of truth).
class UserProfile {
  final String id;
  final PrimaryGoal primaryGoal;
  final int daysPerWeek;
  final int sessionLengthMinutes;
  final EquipmentAccess equipment;
  final ExperienceLevel experienceLevel;
  final String? injuriesNotes;
  final double? weightKg;
  final double? heightCm;
  final DateTime? onboardingCompletedAt;
  final int? age;
  final List<String>? blockedDays;

  const UserProfile({
    required this.id,
    required this.primaryGoal,
    required this.daysPerWeek,
    required this.sessionLengthMinutes,
    required this.equipment,
    required this.experienceLevel,
    this.injuriesNotes,
    this.weightKg,
    this.heightCm,
    this.onboardingCompletedAt,
    this.age,
    this.blockedDays,
  });

  bool get hasCompletedOnboarding => onboardingCompletedAt != null;

  /// Whether we should show weight/height step (goal is lose fat or general fitness).
  bool get shouldCollectWeightHeight =>
      primaryGoal == PrimaryGoal.loseFat || primaryGoal == PrimaryGoal.generalFitness;

  UserProfile copyWith({
    String? id,
    PrimaryGoal? primaryGoal,
    int? daysPerWeek,
    int? sessionLengthMinutes,
    EquipmentAccess? equipment,
    ExperienceLevel? experienceLevel,
    String? injuriesNotes,
    double? weightKg,
    double? heightCm,
    DateTime? onboardingCompletedAt,
    int? age,
    List<String>? blockedDays,
  }) {
    return UserProfile(
      id: id ?? this.id,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      sessionLengthMinutes: sessionLengthMinutes ?? this.sessionLengthMinutes,
      equipment: equipment ?? this.equipment,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      injuriesNotes: injuriesNotes ?? this.injuriesNotes,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      onboardingCompletedAt:
          onboardingCompletedAt ?? this.onboardingCompletedAt,
      age: age ?? this.age,
      blockedDays: blockedDays ?? this.blockedDays,
    );
  }
}
