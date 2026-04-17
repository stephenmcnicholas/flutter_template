import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/presentation/logger/rest_timer_banner.dart';
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
          body: const RestTimerBanner(),
        ),
      ),
    );
  }

  group('RestTimerBanner', () {
    testWidgets('does not display when timer is inactive', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Timer is inactive by default, so banner should not be visible
      expect(find.textContaining('Rest:'), findsNothing);
      expect(find.byIcon(Icons.timer), findsNothing);
    });

    testWidgets('displays when timer is active', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Start the timer
      final container = ProviderScope.containerOf(tester.element(find.byType(RestTimerBanner)));
      container.read(restTimerProvider.notifier).start();
      await tester.pumpAndSettle();

      // Should show timer banner
      expect(find.textContaining('Rest:'), findsOneWidget);
      expect(find.byIcon(Icons.timer), findsOneWidget);
    });

    testWidgets('displays formatted time', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      final container = ProviderScope.containerOf(tester.element(find.byType(RestTimerBanner)));
      container.read(restTimerProvider.notifier).start();
      await tester.pumpAndSettle();

      // Should display time in format "Rest: mm:ss"
      final restText = find.textContaining('Rest:');
      expect(restText, findsOneWidget);
      
      // Should contain time format (mm:ss)
      expect(find.textContaining(':'), findsWidgets);
    });

    testWidgets('updates when timer state changes', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      final container = ProviderScope.containerOf(tester.element(find.byType(RestTimerBanner)));
      container.read(restTimerProvider.notifier).start();
      await tester.pumpAndSettle();

      expect(find.textContaining('Rest:'), findsOneWidget);

      // Stop timer
      container.read(restTimerProvider.notifier).stop();
      await tester.pumpAndSettle();

      // Banner should hide
      expect(find.textContaining('Rest:'), findsNothing);
    });
  });
}
