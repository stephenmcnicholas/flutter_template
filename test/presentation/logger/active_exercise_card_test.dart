import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/exercise_history_provider.dart';
import 'package:fytter/src/presentation/logger/active_exercise_card.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/utils/format_utils.dart' show WeightUnit, DistanceUnit;
import 'package:drift/drift.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  final testExercise = const Exercise(
    id: 'e1',
    name: 'Squat',
    description: '',
    bodyPart: 'Quads',
  );

  Widget buildCard({
    String? supersetLabel,
    List<Map<String, dynamic>> sets = const [],
  }) {
    final db = AppDatabase.test();
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWith((_) => db),
        lastRecordedValuesProvider.overrideWith(
          (ref, id) async => null,
        ),
      ],
      child: MaterialApp(
        theme: FytterTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ActiveExerciseCard(
              exercise: testExercise,
              sets: sets,
              weightUnit: WeightUnit.kg,
              distanceUnit: DistanceUnit.km,
              supersetLabel: supersetLabel,
              onSetChanged: (_, __, ___, ____) {},
              onCompleteSet: () {},
              onAddSet: () {},
            ),
          ),
        ),
      ),
    );
  }

  group('ActiveExerciseCard', () {
    testWidgets('shows superset label above exercise name when supersetLabel is set',
        (tester) async {
      await tester.pumpWidget(buildCard(
        supersetLabel: 'Superset · Round 1 of 3',
        sets: [
          {'id': 's1', 'reps': 10, 'weight': 50.0, 'isComplete': false},
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Superset · Round 1 of 3'), findsOneWidget);
      expect(find.text('Squat'), findsOneWidget);

      // Badge appears above exercise name
      final badgePos = tester.getTopLeft(find.text('Superset · Round 1 of 3'));
      final namePos = tester.getTopLeft(find.text('Squat'));
      expect(badgePos.dy, lessThan(namePos.dy));
    });

    testWidgets('does not show superset label when supersetLabel is null', (tester) async {
      await tester.pumpWidget(buildCard(
        sets: [
          {'id': 's1', 'reps': 10, 'weight': 50.0, 'isComplete': false},
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Superset'), findsNothing);
      expect(find.text('Squat'), findsOneWidget);
    });

    testWidgets('shows exercise name and Complete Set button', (tester) async {
      await tester.pumpWidget(buildCard(
        sets: [
          {'id': 's1', 'reps': 5, 'weight': 60.0, 'isComplete': false},
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Squat'), findsOneWidget);
      expect(find.text('Complete Set'), findsOneWidget);
    });

    testWidgets('shows All sets complete and last set values when all sets are done', (tester) async {
      await tester.pumpWidget(buildCard(
        sets: [
          {'id': 's1', 'reps': 5, 'weight': 100.0, 'isComplete': true},
          {'id': 's2', 'reps': 5, 'weight': 100.0, 'isComplete': true},
          {'id': 's3', 'reps': 4, 'weight': 95.0, 'isComplete': true},
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('All sets complete'), findsOneWidget);
      expect(find.textContaining('Last set:'), findsOneWidget);
      // Last completed set was 95kg × 4 — should appear in the last set text
      expect(find.textContaining('95'), findsOneWidget);
      // Complete Set button should not appear when all done
      expect(find.text('Complete Set'), findsNothing);
    });

    testWidgets('last set text is hidden when in-progress (not all complete)', (tester) async {
      await tester.pumpWidget(buildCard(
        sets: [
          {'id': 's1', 'reps': 5, 'weight': 100.0, 'isComplete': true},
          {'id': 's2', 'reps': 5, 'weight': 100.0, 'isComplete': false},
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('All sets complete'), findsNothing);
      expect(find.text('Complete Set'), findsOneWidget);
      // Last set row shows the previous completed set
      expect(find.textContaining('Last set:'), findsOneWidget);
    });
  });
}
