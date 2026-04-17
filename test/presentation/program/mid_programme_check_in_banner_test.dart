import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/program.dart';
import 'package:fytter/src/domain/workout_session.dart';
import 'package:fytter/src/presentation/program/mid_programme_check_in_screen.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/utils/program_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('MidProgrammeCheckInBanner shows CTA after 6 sessions when not dismissed', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final program = Program(
      id: 'prog1',
      name: 'Test',
      schedule: [
        ProgramWorkout(workoutId: 'w', scheduledDate: DateTime(2026, 1, 1)),
      ],
    );
    final sessions = List<WorkoutSession>.generate(
      6,
      (i) => WorkoutSession(
        id: 's$i',
        workoutId: 'w',
        date: DateTime(2026, 1, i + 1),
        entries: const [],
      ),
    );
    final keys = programCompletionKeysFromSessions(sessions);
    final statusByKey = programStatusByKey(
      program.schedule,
      keys,
      DateTime(2026, 1, 20),
    );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: MidProgrammeCheckInBanner(
              program: program,
              statusByKey: statusByKey,
              sessions: sessions,
            ),
          ),
        ),
        GoRoute(
          path: '/program/mid-check-in',
          builder: (context, state) {
            final args = state.extra as MidProgrammeCheckInArgs?;
            return Scaffold(body: Text('mid-${args?.milestone ?? 0}'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: FytterTheme.light,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Share feedback'), findsOneWidget);
    await tester.tap(find.text('Share feedback'));
    await tester.pumpAndSettle();
    expect(find.text('mid-1'), findsOneWidget);
  });

  testWidgets('MidProgrammeCheckInBanner hidden when milestone dismissed in prefs', (tester) async {
    SharedPreferences.setMockInitialValues({
      MidProgrammeCheckInArgs.prefsKey('prog1', 1): true,
    });
    final program = Program(
      id: 'prog1',
      name: 'Test',
      schedule: [
        ProgramWorkout(workoutId: 'w', scheduledDate: DateTime(2026, 1, 1)),
      ],
    );
    final sessions = List<WorkoutSession>.generate(
      6,
      (i) => WorkoutSession(
        id: 's$i',
        workoutId: 'w',
        date: DateTime(2026, 1, i + 1),
        entries: const [],
      ),
    );
    final statusByKey = programStatusByKey(
      program.schedule,
      programCompletionKeysFromSessions(sessions),
      DateTime(2026, 1, 20),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: MidProgrammeCheckInBanner(
          program: program,
          statusByKey: statusByKey,
          sessions: sessions,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Share feedback'), findsNothing);
  });
}
