import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/presentation/logger/lets_go_transition_screen.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  const transitionArgs = LetsGoTransitionArgs(
    args: _FakeArgs(),
    workoutName: 'Upper Body',
    durationMinutes: 35,
  );

  Widget createTestWidget() {
    return MaterialApp(
      theme: FytterTheme.light,
      home: LetsGoTransitionScreen(transitionArgs: transitionArgs),
    );
  }

  group('LetsGoTransitionScreen', () {
    testWidgets('shows workout name and duration', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Upper Body'), findsOneWidget);
      expect(find.text('~35 min'), findsOneWidget);
      expect(find.text("Let's go"), findsOneWidget);
    });

    testWidgets('pops after ~1.5s', (tester) async {
      Object? poppedValue;
      await tester.pumpWidget(
        MaterialApp(
          theme: FytterTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.of(context).push<Object>(
                    MaterialPageRoute(
                      builder: (_) => LetsGoTransitionScreen(transitionArgs: transitionArgs),
                    ),
                  );
                  poppedValue = result;
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pump(); // Show pushed route
      await tester.pump(const Duration(milliseconds: 100)); // Ensure transition screen is built
      expect(find.text('Upper Body'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1500)); // Timer fires
      await tester.pump(); // Process the pop
      await tester.pumpAndSettle();

      expect(poppedValue, isNotNull);
      expect(poppedValue, isA<_FakeArgs>());
    });
  });
}

class _FakeArgs {
  const _FakeArgs();
}
