import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/workout.dart';
import 'package:fytter/src/domain/program.dart';
import 'package:fytter/src/domain/program_repository.dart';
import 'package:fytter/src/presentation/program/program_builder_screen.dart';
import 'package:fytter/src/presentation/workout/workout_templates_screen.dart'
    show workoutTemplatesFutureProvider;
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('ProgramBuilderScreen shows form and add workout button', (tester) async {
    final templates = [
      const Workout(id: 'w1', name: 'Leg Day', entries: []),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workoutTemplatesFutureProvider.overrideWith((ref) async => templates),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: const ProgramBuilderScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('New Program'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Add workout'), findsOneWidget);

    final saveButton =
        tester.widget<TextButton>(find.widgetWithText(TextButton, 'Save'));
    expect(saveButton.onPressed, isNull);
  });

  testWidgets('ProgramBuilderScreen shows program reminder toggle', (tester) async {
    final templates = [
      const Workout(id: 'w1', name: 'Leg Day', entries: []),
    ];

    await tester.binding.setSurfaceSize(const Size(800, 900));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workoutTemplatesFutureProvider.overrideWith((ref) async => templates),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: const ProgramBuilderScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Remind me for this program'), findsOneWidget);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(find.text('Uses your global reminder time in Settings'), findsOneWidget);
  });

  testWidgets('ProgramBuilderScreen shows not found state when editing missing program', (tester) async {
    final repo = _FakeProgramRepository(findByIdThrows: true);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          programRepositoryProvider.overrideWithValue(repo),
          workoutTemplatesFutureProvider.overrideWith((ref) async => const <Workout>[]),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: const ProgramBuilderScreen(programId: 'missing'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Program not found'), findsOneWidget);
    expect(find.text('This program may have been deleted.'), findsOneWidget);
  });
}

class _FakeProgramRepository implements ProgramRepository {
  _FakeProgramRepository({this.findByIdThrows = false});

  final bool findByIdThrows;

  @override
  Future<void> delete(String id) async {}

  @override
  Future<List<Program>> findAll() async => const [];

  @override
  Future<Program> findById(String id) async {
    if (findByIdThrows) throw StateError('missing');
    return const Program(id: 'p1', name: 'Program', schedule: []);
  }

  @override
  Future<void> save(Program program) async {}
}
