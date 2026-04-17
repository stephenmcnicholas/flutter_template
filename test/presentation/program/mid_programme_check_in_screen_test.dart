import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:fytter/src/data/session_check_in_repository.dart';
import 'package:fytter/src/domain/session_check_in.dart';
import 'package:fytter/src/presentation/program/mid_programme_check_in_screen.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('MidProgrammeCheckInScreen shows title and options', (tester) async {
    final db = AppDatabase.test();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) => db)],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: const MidProgrammeCheckInScreen(
            args: MidProgrammeCheckInArgs(programId: 'p1', milestone: 1),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Programme check-in'), findsOneWidget);
    expect(find.text('Too easy'), findsOneWidget);
    expect(find.text('About right'), findsOneWidget);
    expect(find.text('Too hard'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('Skip marks milestone dismissed in prefs', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final db = AppDatabase.test();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) => db)],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: const MidProgrammeCheckInScreen(
            args: MidProgrammeCheckInArgs(programId: 'p1', milestone: 2),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(MidProgrammeCheckInArgs.prefsKey('p1', 2)), isTrue);
  });

  testWidgets('Save About right writes mid check-in and dismisses milestone', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final db = AppDatabase.test();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) => db)],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: const MidProgrammeCheckInScreen(
            args: MidProgrammeCheckInArgs(programId: 'p9', milestone: 1),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('About right'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Felt steady');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final repo = SessionCheckInRepository(db);
    final list = await repo.getByProgramme('p9');
    expect(list, hasLength(1));
    expect(list.single.checkInType, CheckInType.midProgramme);
    expect(list.single.rating, CheckInRating.aboutRight);
    expect(list.single.freeText, 'Felt steady');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(MidProgrammeCheckInArgs.prefsKey('p9', 1)), isTrue);
  });
}
