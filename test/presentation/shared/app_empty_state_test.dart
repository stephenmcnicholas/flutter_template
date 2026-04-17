import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/presentation/shared/app_empty_state.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Disable runtime font fetching so tests don't rely on network
  GoogleFonts.config.allowRuntimeFetching = false;
  testWidgets('AppEmptyState renders title and message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: const Scaffold(
          body: AppEmptyState(
            title: 'No items',
            message: 'There are no items to display',
          ),
        ),
      ),
    );

    expect(find.text('No items'), findsOneWidget);
    expect(find.text('There are no items to display'), findsOneWidget);
  });

  testWidgets('AppEmptyState shows icon when provided', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: const Scaffold(
          body: AppEmptyState(
            title: 'Empty',
            icon: Icons.inbox,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.inbox), findsOneWidget);
  });

  testWidgets('AppEmptyState shows action button when provided',
      (tester) async {
    bool actionCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: Scaffold(
          body: AppEmptyState(
            title: 'Empty',
            actionLabel: 'Add Item',
            onAction: () {
              actionCalled = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Add Item'), findsOneWidget);
    await tester.tap(find.text('Add Item'));
    await tester.pumpAndSettle();
    expect(actionCalled, isTrue);
  });

  testWidgets('AppEmptyState does not overflow in tight space',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 240));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: const Scaffold(
          body: SizedBox(
            height: 140,
            child: AppEmptyState(
              title: 'No workouts on this day',
              message: 'Pick another date to see scheduled workouts.',
              icon: Icons.calendar_today,
            ),
          ),
        ),
      ),
    );

    expect(find.text('No workouts on this day'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

