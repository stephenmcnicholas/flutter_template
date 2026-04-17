import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:fytter/src/presentation/onboarding/onboarding_screen.dart';
import 'package:fytter/src/presentation/onboarding/onboarding_strings.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/providers/data_providers.dart';

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

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
      ],
      child: MaterialApp(
        theme: FytterTheme.light,
        darkTheme: FytterTheme.dark,
        themeMode: ThemeMode.light,
        home: const OnboardingScreen(),
      ),
    );
  }

  testWidgets('OnboardingScreen shows welcome step first', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text(OnboardingStrings.welcomeTitle), findsOneWidget);
    expect(find.text(OnboardingStrings.getStarted), findsOneWidget);
  });

  testWidgets('Tapping Get started shows goal step', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();
    await tester.tap(find.text(OnboardingStrings.getStarted));
    await tester.pumpAndSettle();

    expect(find.text(OnboardingStrings.goalTitle), findsOneWidget);
    expect(find.text(OnboardingStrings.goalGetStronger), findsOneWidget);
  });

  testWidgets('Tapping Skip on goal step advances with default', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();
    await tester.tap(find.text(OnboardingStrings.getStarted));
    await tester.pumpAndSettle();
    await tester.tap(find.text(OnboardingStrings.skip));
    await tester.pumpAndSettle();

    expect(find.text(OnboardingStrings.daysTitle), findsOneWidget);
  });

  testWidgets('Selecting goal and Next advances', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();
    await tester.tap(find.text(OnboardingStrings.getStarted));
    await tester.pumpAndSettle();
    await tester.tap(find.text(OnboardingStrings.goalLoseFat));
    await tester.pumpAndSettle();
    await tester.tap(find.text(OnboardingStrings.next));
    await tester.pumpAndSettle();

    expect(find.text(OnboardingStrings.daysTitle), findsOneWidget);
  });

  testWidgets('Reaching done step shows Go to Fytter button', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();
    await tester.tap(find.text(OnboardingStrings.getStarted));
    await tester.pumpAndSettle();
    await tester.tap(find.text(OnboardingStrings.goalLoseFat));
    await tester.pumpAndSettle();
    await tester.tap(find.text(OnboardingStrings.next));
    await tester.pumpAndSettle();
    for (var i = 0; i < 6; i++) {
      await tester.tap(find.text(OnboardingStrings.skip));
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(find.text(OnboardingStrings.doneTitle), findsOneWidget);
    expect(find.text(OnboardingStrings.goToFytter), findsOneWidget);
  });
}
