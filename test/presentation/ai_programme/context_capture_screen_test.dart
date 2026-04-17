import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fytter/src/domain/user_profile.dart';
import 'package:fytter/src/presentation/ai_programme/context_capture_screen.dart';
import 'package:fytter/src/presentation/ai_programme/ai_programme_strings.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/providers/user_profile_provider.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/programme_generation_provider.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/exercise_enums.dart';

void main() {
  late AppDatabase db;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    db = AppDatabase.test();
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestWidget({UserProfile? profile, List<Exercise>? exercises}) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        aiProgrammePremiumProvider.overrideWith((ref) => true),
        userProfileProvider.overrideWith((ref) =>
            Future.value(profile)), // null when not passed
        if (exercises != null)
          exercisesFutureProvider.overrideWith((ref) => Future.value(exercises)),
      ],
      child: MaterialApp(
        theme: FytterTheme.light,
        home: const ContextCaptureScreen(),
      ),
    );
  }

  testWidgets('ContextCaptureScreen shows intro first', (tester) async {
    await tester.pumpWidget(buildTestWidget(exercises: [
      Exercise(
        id: 'e1',
        name: 'Squat',
        movementPattern: MovementPattern.squat,
        equipment: 'barbell',
        safetyTier: SafetyTier.tier1,
      ),
    ]));
    await tester.pumpAndSettle();

    expect(find.text(AiProgrammeStrings.introHeadline), findsOneWidget);
    expect(find.text(AiProgrammeStrings.introCta), findsOneWidget);
  });

  testWidgets('Tapping Next advances to days step', (tester) async {
    await tester.pumpWidget(buildTestWidget(exercises: [
      Exercise(
        id: 'e1',
        name: 'Squat',
        movementPattern: MovementPattern.squat,
        equipment: 'barbell',
        safetyTier: SafetyTier.tier1,
      ),
    ]));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AiProgrammeStrings.introCta));
    await tester.pumpAndSettle();
    expect(find.text(AiProgrammeStrings.goalHeadline), findsOneWidget);
    await tester.tap(find.text(AiProgrammeStrings.next));
    await tester.pumpAndSettle();

    expect(find.text(AiProgrammeStrings.daysHeadline), findsOneWidget);
  });

  testWidgets('Next advances through steps', (tester) async {
    await tester.pumpWidget(buildTestWidget(exercises: [
      Exercise(
        id: 'e1',
        name: 'Squat',
        movementPattern: MovementPattern.squat,
        equipment: 'barbell',
        safetyTier: SafetyTier.tier1,
      ),
    ]));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AiProgrammeStrings.introCta));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AiProgrammeStrings.next));
    await tester.pumpAndSettle();
    expect(find.text(AiProgrammeStrings.daysHeadline), findsOneWidget);
    await tester.tap(find.text(AiProgrammeStrings.next));
    await tester.pumpAndSettle();
    expect(find.text(AiProgrammeStrings.blockedDaysHeadline), findsOneWidget);
  });

  testWidgets('Reaching done step shows Build my programme button', (tester) async {
    await tester.pumpWidget(buildTestWidget(exercises: [
      Exercise(
        id: 'e1',
        name: 'Squat',
        movementPattern: MovementPattern.squat,
        equipment: 'barbell',
        safetyTier: SafetyTier.tier1,
      ),
    ]));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AiProgrammeStrings.introCta));
    await tester.pumpAndSettle();
    for (var i = 0; i < 10; i++) {
      await tester.tap(find.text(AiProgrammeStrings.next));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();

    expect(find.text(AiProgrammeStrings.buildMyProgrammeCta), findsOneWidget);
  });

  testWidgets('Pre-fill from profile applies goal and days', (tester) async {
    final profile = UserProfile(
      id: 'local',
      primaryGoal: PrimaryGoal.buildMuscle,
      daysPerWeek: 4,
      sessionLengthMinutes: 60,
      equipment: EquipmentAccess.fullGym,
      experienceLevel: ExperienceLevel.some,
    );
    await tester.pumpWidget(buildTestWidget(profile: profile, exercises: [
      Exercise(
        id: 'e1',
        name: 'Squat',
        movementPattern: MovementPattern.squat,
        equipment: 'barbell',
        safetyTier: SafetyTier.tier1,
      ),
    ]));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AiProgrammeStrings.introCta));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(AiProgrammeStrings.goalBuildMuscle), findsOneWidget);
  });
}
