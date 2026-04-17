import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/presentation/logger/rest_timer_overlay.dart';
import 'package:fytter/src/providers/rest_timer_provider.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Disable runtime font fetching so tests don't rely on network
  GoogleFonts.config.allowRuntimeFetching = false;

  Widget createTestWidget() {
    return ProviderScope(
      child: MaterialApp(
        theme: FytterTheme.light,
        home: Scaffold(
          body: const RestTimerOverlay(),
        ),
      ),
    );
  }

  group('RestTimerOverlay', () {
    testWidgets('does not display when timer is inactive', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Timer is inactive by default, so overlay should not be visible
      expect(find.byType(RestTimerOverlay), findsOneWidget);
      expect(find.text('Rest Timer'), findsNothing);
    });

    testWidgets('displays when timer is active', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Start the timer
      final container = ProviderScope.containerOf(tester.element(find.byType(RestTimerOverlay)));
      container.read(restTimerProvider.notifier).start();
      await tester.pumpAndSettle();

      // Should show timer overlay
      expect(find.text('Rest Timer'), findsOneWidget);
      expect(find.textContaining(':'), findsWidgets); // Time display
    });

    testWidgets('displays timer controls', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      final container = ProviderScope.containerOf(tester.element(find.byType(RestTimerOverlay)));
      container.read(restTimerProvider.notifier).start();
      await tester.pumpAndSettle();

      // Should show control buttons
      expect(find.text('Skip'), findsOneWidget);
      expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget); // Decrease
      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget); // Increase
    });

    testWidgets('skip button stops timer', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      final container = ProviderScope.containerOf(tester.element(find.byType(RestTimerOverlay)));
      container.read(restTimerProvider.notifier).start();
      await tester.pumpAndSettle();

      expect(find.text('Rest Timer'), findsOneWidget);

      // Tap skip button
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Timer should be stopped, overlay should hide
      expect(find.text('Rest Timer'), findsNothing);
    });

    testWidgets('increase button adds 15 seconds', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      final container = ProviderScope.containerOf(tester.element(find.byType(RestTimerOverlay)));
      container.read(restTimerProvider.notifier).start();
      await tester.pumpAndSettle();

      final initialState = container.read(restTimerProvider);
      final initialSeconds = initialState.remainingSeconds;

      // Tap increase button
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      final newState = container.read(restTimerProvider);
      expect(newState.remainingSeconds, initialSeconds + 15);
    });

    testWidgets('decrease button subtracts 15 seconds', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      final container = ProviderScope.containerOf(tester.element(find.byType(RestTimerOverlay)));
      container.read(restTimerProvider.notifier).start();
      await tester.pumpAndSettle();

      final initialState = container.read(restTimerProvider);
      final initialSeconds = initialState.remainingSeconds;

      // Tap decrease button
      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pumpAndSettle();

      final newState = container.read(restTimerProvider);
      expect(newState.remainingSeconds, initialSeconds - 15);
    });

    testWidgets('displays formatted time correctly', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final container = ProviderScope.containerOf(tester.element(find.byType(RestTimerOverlay)));
      container.read(restTimerProvider.notifier).start();
      await tester.pumpAndSettle();

      // Should display time in mm:ss format
      final timeText = find.textContaining(':');
      expect(timeText, findsWidgets);
    });

    testWidgets('shows custom title and subtitle when provided', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final container = ProviderScope.containerOf(tester.element(find.byType(RestTimerOverlay)));
      container.read(restTimerProvider.notifier).start(
        customTitle: 'Round 1 complete',
        customSubtitle: '2 more rounds to go',
      );
      await tester.pumpAndSettle();

      expect(find.text('Round 1 complete'), findsOneWidget);
      expect(find.text('2 more rounds to go'), findsOneWidget);
      expect(find.text('Rest Timer'), findsNothing);
    });

    testWidgets('shows default Rest Timer title when no custom title', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final container = ProviderScope.containerOf(tester.element(find.byType(RestTimerOverlay)));
      container.read(restTimerProvider.notifier).start();
      await tester.pumpAndSettle();

      expect(find.text('Rest Timer'), findsOneWidget);
    });
  });
}
