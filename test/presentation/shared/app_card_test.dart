import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/presentation/shared/app_card.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Disable runtime font fetching so tests don't rely on network
  GoogleFonts.config.allowRuntimeFetching = false;
  testWidgets('AppCard renders with child content', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: const Scaffold(
          body: AppCard(
            child: Text('Card Content'),
          ),
        ),
      ),
    );

    expect(find.text('Card Content'), findsOneWidget);
    expect(find.byType(DecoratedBox), findsOneWidget);
  });

  testWidgets('AppCard uses custom padding when provided', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: Scaffold(
          body: AppCard(
            padding: const EdgeInsets.all(32),
            child: const Text('Content'),
          ),
        ),
      ),
    );

    // Find all Padding widgets and verify at least one has the custom padding
    final paddingWidgets = tester.widgetList<Padding>(find.byType(Padding));
    final hasCustomPadding = paddingWidgets.any(
      (padding) => padding.padding == const EdgeInsets.all(32),
    );
    expect(hasCustomPadding, isTrue, reason: 'AppCard should use custom padding of 32');
  });

  testWidgets('AppCard is tappable when onTap is provided', (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: Scaffold(
          body: AppCard(
            onTap: () {
              tapped = true;
            },
            child: const Text('Tappable'),
          ),
        ),
      ),
    );

    expect(find.byType(InkWell), findsOneWidget);
    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });

  testWidgets('AppCard uses custom elevation when provided', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: const Scaffold(
          body: AppCard(
            elevation: 8,
            child: Text('Content'),
          ),
        ),
      ),
    );

    final context = tester.element(find.byType(AppCard));
    final shadows = context.themeExt<AppShadows>();
    final decoratedBox = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    final decoration = decoratedBox.decoration as BoxDecoration;
    final boxShadows = decoration.boxShadow ?? const <BoxShadow>[];

    expect(boxShadows.length, shadows.strong.length);
    for (var i = 0; i < boxShadows.length; i++) {
      expect(boxShadows[i], shadows.strong[i]);
    }
  });
}

