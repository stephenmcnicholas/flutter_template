import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/presentation/program/program_list_screen.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/filter_sort_providers.dart';
import 'package:fytter/src/providers/programme_generation_provider.dart';
import 'package:fytter/src/presentation/ai_programme/ai_programme_strings.dart';
import 'package:fytter/src/domain/program.dart';
import 'package:fytter/src/presentation/shared/app_loading_state.dart';
import 'package:fytter/src/presentation/shared/app_stats_row.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('ProgramListScreen renders and shows empty state', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          programsFutureProvider.overrideWith((ref) => Future.value([])),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(
            body: const ProgramListScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No programs yet'), findsOneWidget);
  });

  testWidgets('ProgramListScreen displays programs list', (WidgetTester tester) async {
    final programs = [
      const Program(id: 'p1', name: 'Program 1', schedule: []),
      Program(id: 'p2', name: 'Program 2', schedule: [
        ProgramWorkout(workoutId: 'w1', scheduledDate: DateTime(2024, 1, 1)),
      ]),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          programsFutureProvider.overrideWith((ref) async => programs),
        ],
        child: MaterialApp.router(
          theme: FytterTheme.light,
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => Scaffold(
                  body: const ProgramListScreen(),
                ),
              ),
              GoRoute(
                path: '/programs/:id',
                builder: (context, state) => Scaffold(
                  body: Text('Edit ${state.pathParameters['id']}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Program 1'), findsOneWidget);
    expect(find.text('Program 2'), findsOneWidget);
    expect(find.byType(AppStatsRow), findsNWidgets(2));
    expect(find.text('# Workouts'), findsWidgets);
    expect(find.text('Next Workout'), findsWidgets);
  });

  testWidgets('ProgramListScreen filters by date and clears filter', (WidgetTester tester) async {
    final programs = [
      Program(
        id: 'p1',
        name: 'Program 1',
        schedule: [
          ProgramWorkout(workoutId: 'w1', scheduledDate: DateTime(2024, 1, 10)),
        ],
      ),
      Program(
        id: 'p2',
        name: 'Program 2',
        schedule: [
          ProgramWorkout(workoutId: 'w2', scheduledDate: DateTime(2024, 2, 10)),
        ],
      ),
    ];

    final container = ProviderContainer(
      overrides: [
        programsFutureProvider.overrideWith((ref) async => programs),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(
            body: const ProgramListScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Program 1'), findsOneWidget);
    expect(find.text('Program 2'), findsOneWidget);

    container.read(programDateFilterProvider.notifier).state = DateTime(2024, 1, 10);
    await tester.pumpAndSettle();

    expect(find.text('Program 1'), findsOneWidget);
    expect(find.text('Program 2'), findsNothing);
    expect(find.textContaining('Showing programs on'), findsOneWidget);

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(find.text('Program 2'), findsOneWidget);
  });

  testWidgets('ProgramListScreen copy shows info for empty schedule', (WidgetTester tester) async {
    final programs = [
      const Program(id: 'p1', name: 'Program 1', schedule: []),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          programsFutureProvider.overrideWith((ref) async => programs),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(
            body: const ProgramListScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();

    expect(find.text('Nothing to copy'), findsOneWidget);
    expect(find.text('This program has no scheduled workouts.'), findsOneWidget);
  });

  testWidgets('ProgramListScreen shows loading indicator', (WidgetTester tester) async {
    final completer = Completer<List<Program>>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          programsFutureProvider.overrideWith((ref) => completer.future),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(
            body: const ProgramListScreen(),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.byType(AppLoadingState), findsOneWidget);
  });

  testWidgets('ProgramListScreen shows error message', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          programsFutureProvider.overrideWith((ref) => Future.error('Test error')),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(
            body: const ProgramListScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Unable to load programs'), findsOneWidget);
  });

  testWidgets('ProgramListScreen shows AI programme card and teaser when not premium', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          programsFutureProvider.overrideWith((ref) => Future.value([])),
          aiProgrammePremiumProvider.overrideWith((ref) => false),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(
            body: const ProgramListScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AiProgrammeStrings.teaserTitle), findsOneWidget);
    expect(find.text(AiProgrammeStrings.teaserCta), findsOneWidget);
  });

  testWidgets('ProgramListScreen shows AI programme card when premium', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          programsFutureProvider.overrideWith((ref) => Future.value([])),
          aiProgrammePremiumProvider.overrideWith((ref) => true),
        ],
        child: MaterialApp.router(
          theme: FytterTheme.light,
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => Scaffold(
                  body: const ProgramListScreen(),
                ),
              ),
              GoRoute(
                path: '/ai-programme/create',
                builder: (context, state) => const Scaffold(
                  body: Text('Context capture'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AiProgrammeStrings.teaserTitle), findsOneWidget);
    await tester.tap(find.text(AiProgrammeStrings.teaserTitle));
    await tester.pumpAndSettle();
    expect(find.text('Context capture'), findsOneWidget);
  });
} 