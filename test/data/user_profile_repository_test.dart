import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:fytter/src/data/user_profile_repository.dart';
import 'package:fytter/src/domain/user_profile.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late UserProfileRepository repo;

  setUp(() {
    db = AppDatabase.test();
    repo = UserProfileRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('getProfile when empty returns null', () async {
    final profile = await repo.getProfile();
    expect(profile, null);
  });

  test('saveProfile then getProfile returns saved data', () async {
    final toSave = UserProfile(
      id: kLocalProfileId,
      primaryGoal: PrimaryGoal.getStronger,
      daysPerWeek: 4,
      sessionLengthMinutes: 60,
      equipment: EquipmentAccess.fullGym,
      experienceLevel: ExperienceLevel.some,
      injuriesNotes: null,
      weightKg: 80,
      heightCm: 180,
      onboardingCompletedAt: null,
    );
    await repo.saveProfile(toSave);

    final loaded = await repo.getProfile();
    expect(loaded != null, true);
    expect(loaded!.id, kLocalProfileId);
    expect(loaded.primaryGoal, PrimaryGoal.getStronger);
    expect(loaded.daysPerWeek, 4);
    expect(loaded.sessionLengthMinutes, 60);
    expect(loaded.equipment, EquipmentAccess.fullGym);
    expect(loaded.experienceLevel, ExperienceLevel.some);
    expect(loaded.weightKg, 80);
    expect(loaded.heightCm, 180);
    expect(loaded.onboardingCompletedAt, null);
  });

  test('markOnboardingCompleted sets timestamp', () async {
    final profile = UserProfile(
      id: kLocalProfileId,
      primaryGoal: PrimaryGoal.generalFitness,
      daysPerWeek: 3,
      sessionLengthMinutes: 45,
      equipment: EquipmentAccess.homeDumbbells,
      experienceLevel: ExperienceLevel.never,
    );
    await repo.saveProfile(profile);
    expect((await repo.getProfile())!.onboardingCompletedAt, null);

    await repo.markOnboardingCompleted();
    final after = await repo.getProfile();
    expect(after != null, true);
    expect(after!.onboardingCompletedAt != null, true);
  });
}
