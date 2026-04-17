import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/presentation/shared/more_menu.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('MoreMenu shows Settings and Profile options and closes on tap', (WidgetTester tester) async {
    bool closed = false;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => const MoreMenu(),
                  ).then((_) {
                    closed = true;
                  });
                },
                child: const Text('Open MoreMenu'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const SizedBox.shrink(),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
      ),
    );

    // Open the MoreMenu
    await tester.tap(find.text('Open MoreMenu'));
    await tester.pumpAndSettle();

    // Verify both options are present
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Tap Settings and verify the modal closes
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
  });

  testWidgets('MoreMenu closes when Profile is tapped', (WidgetTester tester) async {
    bool closed = false;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => const MoreMenu(),
                  ).then((_) {
                    closed = true;
                  });
                },
                child: const Text('Open MoreMenu'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const SizedBox.shrink(),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
      ),
    );

    await tester.tap(find.text('Open MoreMenu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
  });
} 