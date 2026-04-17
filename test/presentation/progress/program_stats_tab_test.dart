import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/presentation/progress/program_stats_tab.dart';
import 'package:fytter/src/providers/progress_provider.dart';
import 'package:fytter/src/providers/navigation_provider.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('ProgramStatsTab shows stats and program completion', (tester) async {
    final stats = ProgramStats(
      totalPrograms: 2,
      completionRate: 0.5,
      programCompletionStats: [
        ProgramCompletionStat(
          programName: 'Push',
          startDate: DateTime(2026, 1, 19),
          completedCount: 1,
          totalCount: 4,
        ),
        ProgramCompletionStat(
          programName: 'Pull',
          startDate: DateTime(2026, 2, 2),
          completedCount: 2,
          totalCount: 6,
        ),
      ],
      completedPrograms: 1,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          programStatsProvider.overrideWith((ref) => Future.value(stats)),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(body: ProgramStatsTab()),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Total Programs'), findsOneWidget);
    expect(find.text('Completion Rate'), findsOneWidget);
    expect(find.text('Program Completion'), findsOneWidget);
    expect(find.text('Push'), findsOneWidget);
    expect(find.text('Pull'), findsOneWidget);
  });

  testWidgets('ProgramStatsTab navigates to Programs tab on total tap', (tester) async {
    final stats = ProgramStats(
      totalPrograms: 1,
      completionRate: 0.0,
      programCompletionStats: [
        ProgramCompletionStat(
          programName: 'Phase 1',
          startDate: DateTime(2026, 1, 19),
          completedCount: 0,
          totalCount: 12,
        ),
      ],
      completedPrograms: 0,
    );
    final container = ProviderContainer(
      overrides: [
        programStatsProvider.overrideWith((ref) => Future.value(stats)),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(body: ProgramStatsTab()),
        ),
      ),
    );
    await tester.pump();

    expect(container.read(selectedTabIndexProvider), 0);
    await tester.tap(find.byKey(const Key('programStats_totalPrograms')));
    await tester.pump();
    expect(container.read(selectedTabIndexProvider), 2);
  });

  testWidgets('ProgramStatsTab shows empty state', (tester) async {
    final stats = ProgramStats(
      totalPrograms: 0,
      completionRate: 0.0,
      programCompletionStats: [],
      completedPrograms: 0,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          programStatsProvider.overrideWith((ref) => Future.value(stats)),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(body: ProgramStatsTab()),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('No programs available'), findsOneWidget);
  });

  testWidgets('ProgramStatsTab shows error state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          programStatsProvider.overrideWith((ref) => Future.error('error')),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(body: ProgramStatsTab()),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Unable to load stats'), findsOneWidget);
  });
} 