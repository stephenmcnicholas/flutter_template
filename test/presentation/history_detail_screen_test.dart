import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/presentation/history/history_detail_screen.dart';
import 'package:fytter/src/providers/workout_session_provider.dart';
import 'package:fytter/src/domain/workout_session.dart';
import 'package:fytter/src/domain/workout_entry.dart';
import 'dart:async';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/exercise_input_type.dart';
import 'package:fytter/src/domain/session_check_in.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/presentation/workout/workout_templates_screen.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  group('HistoryDetailScreen', () {
    const testSessionId = 'session42';

    // Dummy workout entry structure matching the screen's expectations
    final dummyEntry = WorkoutEntry(
      id: 'e1',
      exerciseId: 'Squat',
      reps: 5,
      weight: 100.0,
      isComplete: true,
      timestamp: DateTime(2024, 5, 20),
    );
    final dummySession = WorkoutSession(
      id: 'session1',
      workoutId: 'w1',
      date: DateTime(2024, 5, 20, 8, 0),
      name: 'Push Day',
      notes: 'Felt good',
      entries: [dummyEntry],
    );

    testWidgets('shows loading indicator while loading', (tester) async {
      final completer = Completer<WorkoutSession>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workoutSessionByIdProvider.overrideWith((ref, id) => completer.future),
            workoutSessionsProvider.overrideWith((ref) async => []),
            workoutTemplatesFutureProvider.overrideWith((ref) async => const []),
            sessionCheckInsForSessionProvider.overrideWith((ref, id) async => []),
          ],
          child: MaterialApp(
            theme: FytterTheme.light,
            home: const HistoryDetailScreen(workoutId: testSessionId),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message on error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workoutSessionByIdProvider.overrideWith((ref, id) => throw Exception('fail')),
            workoutSessionsProvider.overrideWith((ref) async => []),
            workoutTemplatesFutureProvider.overrideWith((ref) async => const []),
            sessionCheckInsForSessionProvider.overrideWith((ref, id) async => []),
          ],
          child: MaterialApp(
            theme: FytterTheme.light,
            home: const HistoryDetailScreen(workoutId: testSessionId),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Error loading workout'), findsOneWidget);
    });

    testWidgets('shows session details and entries', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workoutSessionByIdProvider.overrideWith((ref, id) async => dummySession),
            workoutSessionsProvider.overrideWith((ref) async => [dummySession]),
            exercisesFutureProvider.overrideWith((ref) async => [
              const Exercise(
                id: 'Squat',
                name: 'Squat',
                description: '',
                loggingType: ExerciseInputType.repsAndWeight,
              ),
            ]),
            workoutTemplatesFutureProvider.overrideWith((ref) async => const []),
            sessionCheckInsForSessionProvider.overrideWith((ref, id) async => []),
          ],
          child: MaterialApp(
            theme: FytterTheme.light,
            home: const HistoryDetailScreen(workoutId: testSessionId),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Title and date/time label
      expect(find.text('Push Day'), findsOneWidget);
      expect(find.text('20 May, 2024 • 08:00'), findsOneWidget);
      // Entry details
      expect(find.text('Squat'), findsOneWidget);
      expect(find.text('5 reps @ 100.0 kg'), findsOneWidget);
    });

    testWidgets('formats repsOnly entries correctly', (tester) async {
      final entry = WorkoutEntry(
        id: 'e1',
        exerciseId: 'pushup',
        reps: 20,
        weight: 0.0,
        isComplete: true,
        timestamp: DateTime(2024, 5, 20),
      );
      final session = WorkoutSession(
        id: 'session1',
        workoutId: 'w1',
        date: DateTime(2024, 5, 20, 8, 0),
        name: 'Bodyweight Day',
        entries: [entry],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workoutSessionByIdProvider.overrideWith((ref, id) async => session),
            workoutSessionsProvider.overrideWith((ref) async => [session]),
            exercisesFutureProvider.overrideWith((ref) async => [
              const Exercise(
                id: 'pushup',
                name: 'Push-up',
                description: '',
                bodyPart: 'Chest',
                equipment: 'Bodyweight',
                loggingType: ExerciseInputType.repsOnly,
              ),
            ]),
            workoutTemplatesFutureProvider.overrideWith((ref) async => const []),
            sessionCheckInsForSessionProvider.overrideWith((ref, id) async => []),
          ],
          child: MaterialApp(
            theme: FytterTheme.light,
            home: const HistoryDetailScreen(workoutId: testSessionId),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('20 reps'), findsOneWidget);
    });

    testWidgets('formats distanceAndTime entries correctly', (tester) async {
      final entry = WorkoutEntry(
        id: 'e1',
        exerciseId: 'running',
        reps: 0,
        weight: 0.0,
        distance: 5.0,
        duration: 1800,
        isComplete: true,
        timestamp: DateTime(2024, 5, 20),
      );
      final session = WorkoutSession(
        id: 'session1',
        workoutId: 'w1',
        date: DateTime(2024, 5, 20, 8, 0),
        name: 'Cardio Day',
        entries: [entry],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workoutSessionByIdProvider.overrideWith((ref, id) async => session),
            workoutSessionsProvider.overrideWith((ref) async => [session]),
            exercisesFutureProvider.overrideWith((ref) async => [
              const Exercise(
                id: 'running',
                name: 'Running',
                description: '',
                bodyPart: 'Cardio',
                equipment: 'Bodyweight',
                loggingType: ExerciseInputType.distanceAndTime,
              ),
            ]),
            workoutTemplatesFutureProvider.overrideWith((ref) async => const []),
            sessionCheckInsForSessionProvider.overrideWith((ref, id) async => []),
          ],
          child: MaterialApp(
            theme: FytterTheme.light,
            home: const HistoryDetailScreen(workoutId: testSessionId),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('5.0 km'), findsOneWidget);
      expect(find.textContaining('30:00'), findsOneWidget);
    });

    testWidgets('formats timeOnly entries correctly', (tester) async {
      final entry = WorkoutEntry(
        id: 'e1',
        exerciseId: 'plank',
        reps: 0,
        weight: 0.0,
        duration: 60,
        isComplete: true,
        timestamp: DateTime(2024, 5, 20),
      );
      final session = WorkoutSession(
        id: 'session1',
        workoutId: 'w1',
        date: DateTime(2024, 5, 20, 8, 0),
        name: 'Core Day',
        entries: [entry],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workoutSessionByIdProvider.overrideWith((ref, id) async => session),
            workoutSessionsProvider.overrideWith((ref) async => [session]),
            exercisesFutureProvider.overrideWith((ref) async => [
              const Exercise(
                id: 'plank',
                name: 'Plank',
                description: '',
                bodyPart: 'Core',
                equipment: 'Bodyweight',
                loggingType: ExerciseInputType.timeOnly,
              ),
            ]),
            workoutTemplatesFutureProvider.overrideWith((ref) async => const []),
            sessionCheckInsForSessionProvider.overrideWith((ref, id) async => []),
          ],
          child: MaterialApp(
            theme: FytterTheme.light,
            home: const HistoryDetailScreen(workoutId: testSessionId),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1:00'), findsOneWidget);
    });

    testWidgets('excludes incomplete entries from display', (tester) async {
      final completeEntry = WorkoutEntry(
        id: 'e1',
        exerciseId: 'Squat',
        reps: 5,
        weight: 100.0,
        isComplete: true,
        timestamp: DateTime(2024, 5, 20),
      );
      final incompleteEntry = WorkoutEntry(
        id: 'e2',
        exerciseId: 'Squat',
        reps: 3,
        weight: 80.0,
        isComplete: false,
        timestamp: DateTime(2024, 5, 20),
      );
      final session = WorkoutSession(
        id: 'session1',
        workoutId: 'w1',
        date: DateTime(2024, 5, 20, 8, 0),
        name: 'Mixed Sets',
        entries: [completeEntry, incompleteEntry],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workoutSessionByIdProvider.overrideWith((ref, id) async => session),
            workoutSessionsProvider.overrideWith((ref) async => [session]),
            exercisesFutureProvider.overrideWith((ref) async => [
              const Exercise(
                id: 'Squat',
                name: 'Squat',
                description: '',
                loggingType: ExerciseInputType.repsAndWeight,
              ),
            ]),
            workoutTemplatesFutureProvider.overrideWith((ref) async => const []),
            sessionCheckInsForSessionProvider.overrideWith((ref, id) async => []),
          ],
          child: MaterialApp(
            theme: FytterTheme.light,
            home: const HistoryDetailScreen(workoutId: testSessionId),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('5 reps @ 100.0 kg'), findsOneWidget);
      expect(find.text('3 reps @ 80.0 kg'), findsNothing);
    });

    testWidgets('Superset group shows SUPERSET label with left border', (tester) async {
      const groupId = 'group-abc';
      final entry1 = WorkoutEntry(
        id: 'e1',
        exerciseId: 'squat',
        reps: 5,
        weight: 100.0,
        isComplete: true,
        timestamp: DateTime(2024, 5, 20),
        supersetGroupId: groupId,
      );
      final entry2 = WorkoutEntry(
        id: 'e2',
        exerciseId: 'bench',
        reps: 8,
        weight: 60.0,
        isComplete: true,
        timestamp: DateTime(2024, 5, 20),
        supersetGroupId: groupId,
      );
      final session = WorkoutSession(
        id: 'session1',
        workoutId: 'w1',
        date: DateTime(2024, 5, 20, 8, 0),
        name: 'Superset Day',
        entries: [entry1, entry2],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workoutSessionByIdProvider.overrideWith((ref, id) async => session),
            workoutSessionsProvider.overrideWith((ref) async => [session]),
            exercisesFutureProvider.overrideWith((ref) async => [
              const Exercise(
                id: 'squat',
                name: 'Squat',
                description: '',
                loggingType: ExerciseInputType.repsAndWeight,
              ),
              const Exercise(
                id: 'bench',
                name: 'Bench Press',
                description: '',
                loggingType: ExerciseInputType.repsAndWeight,
              ),
            ]),
            workoutTemplatesFutureProvider.overrideWith((ref) async => const []),
            sessionCheckInsForSessionProvider.overrideWith((ref, id) async => []),
          ],
          child: MaterialApp(
            theme: FytterTheme.light,
            home: const HistoryDetailScreen(workoutId: testSessionId),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('SUPERSET'), findsOneWidget);
      expect(find.text('Squat'), findsOneWidget);
      expect(find.text('Bench Press'), findsOneWidget);
    });

    testWidgets('shows post-workout rating emoji and label when check-in exists', (tester) async {
      final checkIn = SessionCheckIn(
        id: 'ci1',
        sessionId: 'session42',
        checkInType: CheckInType.postSession,
        rating: CheckInRating.great,
        createdAt: DateTime(2024, 5, 20, 9, 0),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workoutSessionByIdProvider.overrideWith((ref, id) async => dummySession),
            workoutSessionsProvider.overrideWith((ref) async => [dummySession]),
            exercisesFutureProvider.overrideWith((ref) async => []),
            workoutTemplatesFutureProvider.overrideWith((ref) async => const []),
            sessionCheckInsForSessionProvider.overrideWith((ref, id) async => [checkIn]),
          ],
          child: MaterialApp(
            theme: FytterTheme.light,
            home: const HistoryDetailScreen(workoutId: testSessionId),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('💪'), findsOneWidget);
      expect(find.text('Strong'), findsOneWidget);
    });

    testWidgets('shows post-workout note when check-in has free text', (tester) async {
      final checkIn = SessionCheckIn(
        id: 'ci1',
        sessionId: 'session42',
        checkInType: CheckInType.postSession,
        rating: CheckInRating.okay,
        freeText: 'Knees felt a bit stiff today',
        createdAt: DateTime(2024, 5, 20, 9, 0),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workoutSessionByIdProvider.overrideWith((ref, id) async => dummySession),
            workoutSessionsProvider.overrideWith((ref) async => [dummySession]),
            exercisesFutureProvider.overrideWith((ref) async => []),
            workoutTemplatesFutureProvider.overrideWith((ref) async => const []),
            sessionCheckInsForSessionProvider.overrideWith((ref, id) async => [checkIn]),
          ],
          child: MaterialApp(
            theme: FytterTheme.light,
            home: const HistoryDetailScreen(workoutId: testSessionId),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('😐'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
      expect(find.text('Knees felt a bit stiff today'), findsOneWidget);
    });

    testWidgets('shows no check-in section when no post-session check-in', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workoutSessionByIdProvider.overrideWith((ref, id) async => dummySession),
            workoutSessionsProvider.overrideWith((ref) async => [dummySession]),
            exercisesFutureProvider.overrideWith((ref) async => []),
            workoutTemplatesFutureProvider.overrideWith((ref) async => const []),
            sessionCheckInsForSessionProvider.overrideWith((ref, id) async => []),
          ],
          child: MaterialApp(
            theme: FytterTheme.light,
            home: const HistoryDetailScreen(workoutId: testSessionId),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Strong'), findsNothing);
      expect(find.text('OK'), findsNothing);
      expect(find.text('Tough'), findsNothing);
    });

    testWidgets('only post-session check-in shown, not pre-workout', (tester) async {
      final preCheckIn = SessionCheckIn(
        id: 'ci-pre',
        sessionId: 'session42',
        checkInType: CheckInType.preWorkout,
        rating: CheckInRating.amber,
        createdAt: DateTime(2024, 5, 20, 7, 55),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workoutSessionByIdProvider.overrideWith((ref, id) async => dummySession),
            workoutSessionsProvider.overrideWith((ref) async => [dummySession]),
            exercisesFutureProvider.overrideWith((ref) async => []),
            workoutTemplatesFutureProvider.overrideWith((ref) async => const []),
            sessionCheckInsForSessionProvider.overrideWith((ref, id) async => [preCheckIn]),
          ],
          child: MaterialApp(
            theme: FytterTheme.light,
            home: const HistoryDetailScreen(workoutId: testSessionId),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Pre-workout ratings (green/amber/red) have no emoji/label in the history section
      expect(find.text('Strong'), findsNothing);
      expect(find.text('OK'), findsNothing);
      expect(find.text('Tough'), findsNothing);
    });
  });
}

/// Stub for WorkoutEntry matching the fields used in the screen.
class WorkoutEntryStub {
  final String exerciseName;
  final int sets;
  final int reps;
  final double weight;

  WorkoutEntryStub({
    required this.exerciseName,
    required this.sets,
    required this.reps,
    required this.weight,
  });
}

/// Stub for Workout matching the fields used in the screen.
class WorkoutStub {
  final int id;
  final DateTime date;
  final List<WorkoutEntryStub> entries;

  WorkoutStub({
    required this.id,
    required this.date,
    required this.entries,
  });
}
