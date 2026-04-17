import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/presentation/shared/bottom_nav_bar.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  testWidgets('BottomNavBar displays all tabs and responds to taps', (WidgetTester tester) async {
    int tappedIndex = -1;
    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: Scaffold(
          bottomNavigationBar: BottomNavBar(
            currentIndex: 2,
            onTap: (index) {
              tappedIndex = index;
            },
          ),
        ),
      ),
    );

    // Verify all tab labels are present
    expect(find.text('Exercises'), findsOneWidget);
    expect(find.text('Workouts'), findsOneWidget);
    expect(find.text('Programs'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);

    // Tap the 'Workouts' tab (index 1)
    await tester.tap(find.text('Workouts'));
    await tester.pumpAndSettle();
    expect(tappedIndex, 1);
  });
}
