import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/presentation/shared/app_text.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Disable runtime font fetching so tests don't rely on network
  GoogleFonts.config.allowRuntimeFetching = false;
  testWidgets('AppText renders with different styles using tokens',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: const Scaffold(
          body: Column(
            children: [
              AppText('Display', style: AppTextStyle.display),
              AppText('Headline', style: AppTextStyle.headline),
              AppText('Title', style: AppTextStyle.title),
              AppText('Body', style: AppTextStyle.body),
              AppText('Label', style: AppTextStyle.label),
              AppText('Caption', style: AppTextStyle.caption),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Display'), findsOneWidget);
    expect(find.text('Headline'), findsOneWidget);
    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Body'), findsOneWidget);
    expect(find.text('Label'), findsOneWidget);
    expect(find.text('Caption'), findsOneWidget);
  });

  testWidgets('AppText respects custom color and textAlign', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: const Scaffold(
          body: AppText(
            'Test',
            style: AppTextStyle.body,
            color: Colors.red,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );

    final textWidget = tester.widget<Text>(find.text('Test'));
    expect(textWidget.style?.color, Colors.red);
    expect(textWidget.textAlign, TextAlign.center);
  });
}

