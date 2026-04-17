import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/presentation/calendar/calendar_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

void main() {
  testWidgets('CalendarScreen shows calendar and scheduled programs', (tester) async {
    // Build the widget
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: CalendarScreen(initialFocusedDay: DateTime.utc(2025, 5, 1)),
        ),
      ),
    );

    // Ensure the widget tree is fully built
    await tester.pumpAndSettle();

    // Verify basic structure first
    expect(find.byType(Scaffold), findsOneWidget, reason: 'Scaffold should be present');
    expect(find.byType(AppBar), findsOneWidget, reason: 'AppBar should be present');
    expect(find.text('Calendar'), findsOneWidget, reason: 'Calendar title should be present');
    expect(find.byType(FloatingActionButton), findsOneWidget, reason: 'FAB should be present');

    // Find the calendar widget
    final calendarFinder = find.byWidgetPredicate(
      (widget) => widget is TableCalendar<ScheduledProgram>,
      description: 'TableCalendar widget',
    );
    expect(calendarFinder, findsOneWidget, reason: 'TableCalendar should be present');

    // Use the mock data to determine the expected month label
    final mockDate = DateTime.utc(2025, 5, 27); // Should match _mockPrograms[0].date
    final expectedMonthLabel = DateFormat.yMMMM().format(mockDate); // e.g., 'May 2025'

    // Verify we're in the correct month
    expect(find.text(expectedMonthLabel), findsOneWidget, reason: 'Should be in $expectedMonthLabel');

    // Helper function to find and tap a specific day
    Future<void> selectDay(String dateLabel) async {
      final dayCellFinder = find.byWidgetPredicate(
        (widget) {
          if (widget is Semantics) {
            final label = widget.properties.label;
            return label != null && label.contains(dateLabel);
          }
          return false;
        },
        description: 'Day cell for $dateLabel',
      );
      
      expect(dayCellFinder, findsOneWidget, reason: '$dateLabel cell should be present');
      await tester.tap(dayCellFinder);
      await tester.pumpAndSettle();
    }

    // Check May 27th (Push Day)
    await selectDay('May 27, 2025');
    expect(find.text('Push Day'), findsOneWidget, reason: 'Push Day program should be visible');
    expect(find.text('Pull Day'), findsNothing, reason: 'Pull Day should not be visible on May 27');
    expect(find.text('Legs'), findsNothing, reason: 'Legs should not be visible on May 27');

    // Check May 28th (Pull Day)
    await selectDay('May 28, 2025');
    expect(find.text('Push Day'), findsNothing, reason: 'Push Day should not be visible on May 28');
    expect(find.text('Pull Day'), findsOneWidget, reason: 'Pull Day program should be visible');
    expect(find.text('Legs'), findsNothing, reason: 'Legs should not be visible on May 28');

    // Check May 29th (Legs)
    await selectDay('May 29, 2025');
    expect(find.text('Push Day'), findsNothing, reason: 'Push Day should not be visible on May 29');
    expect(find.text('Pull Day'), findsNothing, reason: 'Pull Day should not be visible on May 29');
    expect(find.text('Legs'), findsOneWidget, reason: 'Legs program should be visible');
  });
} 