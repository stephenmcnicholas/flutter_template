import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:fytter/src/presentation/programme/end_programme_review_screen.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('EndProgrammeReviewScreen shows summary and actions', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final db = AppDatabase.test();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) => db)],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: const EndProgrammeReviewScreen(
            args: EndProgrammeReviewArgs(
              programId: 'p1',
              programName: 'Test Programme',
              scheduledWorkouts: 8,
              sessionsLogged: 7,
              totalVolumeKg: 1200,
              totalSets: 42,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Programme complete'), findsOneWidget);
    expect(find.textContaining('Test Programme'), findsWidgets);
    expect(find.textContaining('8 sessions planned'), findsOneWidget);
    expect(find.textContaining('Build my next programme'), findsOneWidget);
    expect(find.text('Maybe later'), findsOneWidget);
  });
}
