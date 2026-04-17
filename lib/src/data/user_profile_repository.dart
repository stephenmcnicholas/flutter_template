import 'package:drift/drift.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:fytter/src/domain/user_profile.dart';

/// Single device profile id (MVP: one row per device).
const String kLocalProfileId = 'local';

/// Persists and loads user profile (onboarding + AI program generation).
class UserProfileRepository {
  UserProfileRepository(this._db);

  final AppDatabase _db;

  /// Reads the current profile; returns null if none exists.
  Future<UserProfile?> getProfile() async {
    final entity = await _db.getUserProfile();
    if (entity == null) return null;
    return _entityToProfile(entity);
  }

  /// Saves the profile (insert or update). Sets [onboardingCompletedAt] when
  /// completing onboarding so we don't show onboarding again.
  Future<void> saveProfile(UserProfile profile) async {
    final companion = UserProfilesCompanion(
      id: Value(profile.id),
      primaryGoal: Value(profile.primaryGoal.toStorage()),
      daysPerWeek: Value(profile.daysPerWeek),
      sessionLengthMinutes: Value(profile.sessionLengthMinutes),
      equipment: Value(profile.equipment.toStorage()),
      experienceLevel: Value(profile.experienceLevel.toStorage()),
      injuriesNotes: Value(profile.injuriesNotes),
      weightKg: Value(profile.weightKg),
      heightCm: Value(profile.heightCm),
      onboardingCompletedAt: Value(profile.onboardingCompletedAt),
      age: Value(profile.age),
      blockedDays: Value(profile.blockedDays?.join(',') ),
    );
    await _db.upsertUserProfile(companion);
  }

  /// Marks onboarding as completed (sets timestamp); keeps other fields unchanged.
  Future<void> markOnboardingCompleted() async {
    final existing = await _db.getUserProfile();
    final companion = UserProfilesCompanion(
      id: const Value(kLocalProfileId),
      onboardingCompletedAt: Value(DateTime.now()),
      primaryGoal: Value(existing?.primaryGoal),
      daysPerWeek: Value(existing?.daysPerWeek),
      sessionLengthMinutes: Value(existing?.sessionLengthMinutes),
      equipment: Value(existing?.equipment),
      experienceLevel: Value(existing?.experienceLevel),
      injuriesNotes: Value(existing?.injuriesNotes),
      weightKg: Value(existing?.weightKg),
      heightCm: Value(existing?.heightCm),
      age: Value(existing?.age),
      blockedDays: Value(existing?.blockedDays),
    );
    await _db.upsertUserProfile(companion);
  }

  UserProfile _entityToProfile(UserProfileEntity e) {
    return UserProfile(
      id: e.id,
      primaryGoal: primaryGoalFromStorage(e.primaryGoal),
      daysPerWeek: e.daysPerWeek ?? kDefaultDaysPerWeek,
      sessionLengthMinutes:
          e.sessionLengthMinutes ?? kDefaultSessionLengthMinutes,
      equipment: equipmentFromStorage(e.equipment),
      experienceLevel: experienceLevelFromStorage(e.experienceLevel),
      injuriesNotes: e.injuriesNotes,
      weightKg: e.weightKg,
      heightCm: e.heightCm,
      onboardingCompletedAt: e.onboardingCompletedAt,
      age: e.age,
      blockedDays: e.blockedDays != null && e.blockedDays!.isNotEmpty
          ? e.blockedDays!.split(',')
          : null,
    );
  }
}

extension on PrimaryGoal {
  String toStorage() => primaryGoalToStorage(this);
}

extension on EquipmentAccess {
  String toStorage() => equipmentToStorage(this);
}

extension on ExperienceLevel {
  String toStorage() => experienceLevelToStorage(this);
}
