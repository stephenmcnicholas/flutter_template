import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/presentation/shared/app_loading_state.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Disable runtime font fetching so tests don't rely on network
  GoogleFonts.config.allowRuntimeFetching = false;
  testWidgets('AppLoadingState shows CircularProgressIndicator by default',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: const Scaffold(
          body: AppLoadingState(),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('AppLoadingState shows message when provided', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: const Scaffold(
          body: AppLoadingState(message: 'Loading...'),
        ),
      ),
    );

    expect(find.text('Loading...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('AppLoadingState shows shimmer when useShimmer is true',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: const Scaffold(
          body: AppLoadingState(useShimmer: true),
        ),
      ),
    );

    // Shimmer widget should be present
    expect(find.byType(AppLoadingState), findsOneWidget);
    // Should not show CircularProgressIndicator when shimmer is used
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}

