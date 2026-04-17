import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/presentation/shared/app_list_row.dart';
import 'package:fytter/src/presentation/shared/app_tap_feedback.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Disable runtime font fetching so tests don't rely on network
  GoogleFonts.config.allowRuntimeFetching = false;
  testWidgets('AppListRow renders with title', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: const Scaffold(
          body: AppListRow(
            title: Text('List Item'),
          ),
        ),
      ),
    );

    expect(find.text('List Item'), findsOneWidget);
    expect(find.byType(ListTile), findsOneWidget);
  });

  testWidgets('AppListRow renders with all optional widgets', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: const Scaffold(
          body: AppListRow(
            leading: Icon(Icons.fitness_center),
            title: Text('Title'),
            subtitle: Text('Subtitle'),
            trailing: Icon(Icons.chevron_right),
          ),
        ),
      ),
    );

    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Subtitle'), findsOneWidget);
    expect(find.byIcon(Icons.fitness_center), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('AppListRow is tappable when onTap is provided', (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: Scaffold(
          body: AppListRow(
            title: const Text('Tappable'),
            onTap: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    final tapFeedback = tester.widget<AppTapFeedback>(find.byType(AppTapFeedback));
    expect(tapFeedback.onTap, isNotNull);

    await tester.tap(find.text('Tappable'));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('AppListRow uses dense layout when dense is true', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: const Scaffold(
          body: AppListRow(
            title: Text('Dense'),
            dense: true,
          ),
        ),
      ),
    );

    final listTile = tester.widget<ListTile>(find.byType(ListTile));
    expect(listTile.dense, isTrue);
  });
}

