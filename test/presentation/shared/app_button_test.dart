import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/presentation/shared/app_button.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Disable runtime font fetching so tests don't rely on network
  GoogleFonts.config.allowRuntimeFetching = false;
  testWidgets('AppButton renders with primary variant', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: Scaffold(
          body: AppButton(
            label: 'Test Button',
            variant: AppButtonVariant.primary,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('Test Button'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('AppButton shows loading state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: Scaffold(
          body: AppButton(
            label: 'Loading',
            isLoading: true,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading'), findsNothing);
  });

  testWidgets('AppButton is disabled when onPressed is null',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: const Scaffold(
          body: AppButton(
            label: 'Disabled',
            onPressed: null,
          ),
        ),
      ),
    );

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('AppButton renders with different variants', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: Scaffold(
          body: Column(
            children: [
              AppButton(
                label: 'Primary',
                variant: AppButtonVariant.primary,
                onPressed: () {},
              ),
              AppButton(
                label: 'Secondary',
                variant: AppButtonVariant.secondary,
                onPressed: () {},
              ),
              AppButton(
                label: 'Destructive',
                variant: AppButtonVariant.destructive,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Primary'), findsOneWidget);
    expect(find.text('Secondary'), findsOneWidget);
    expect(find.text('Destructive'), findsOneWidget);
  });
}

