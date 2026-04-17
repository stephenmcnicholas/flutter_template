import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Disable runtime font fetching so tests don't rely on network
  GoogleFonts.config.allowRuntimeFetching = false;

  test('App theme returns ThemeData', () {
    final theme = FytterTheme.light;
    expect(theme, isNotNull);
  });

  testWidgets('Light theme includes all ThemeExtensions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: const Scaffold(
          body: _TestWidget(),
        ),
      ),
    );

    final context = tester.element(find.byType(_TestWidget));
    final colors = context.themeExt<AppColors>();
    final typography = context.themeExt<AppTypography>();
    final spacing = context.themeExt<AppSpacing>();
    final radii = context.themeExt<AppRadii>();
    final shadows = context.themeExt<AppShadows>();
    final gradients = context.themeExt<AppGradients>();
    final categories = context.themeExt<AppCategoryColors>();

    expect(colors, isNotNull);
    expect(typography, isNotNull);
    expect(spacing, isNotNull);
    expect(radii, isNotNull);
    expect(shadows, isNotNull);
    expect(gradients, isNotNull);
    expect(categories, isNotNull);

    // Verify color roles exist
    expect(colors.primary, isNotNull);
    expect(colors.secondary, isNotNull);
    expect(colors.surface, isNotNull);
    expect(colors.background, isNotNull);
    expect(colors.error, isNotNull);
    expect(colors.success, isNotNull);
    expect(colors.warning, isNotNull);
    expect(colors.outline, isNotNull);

    // Verify typography roles exist
    expect(typography.display, isNotNull);
    expect(typography.headline, isNotNull);
    expect(typography.title, isNotNull);
    expect(typography.body, isNotNull);
    expect(typography.label, isNotNull);
    expect(typography.caption, isNotNull);

    // Verify spacing scale
    expect(spacing.xs, 4.0);
    expect(spacing.sm, 8.0);
    expect(spacing.md, 12.0);
    expect(spacing.lg, 16.0);
    expect(spacing.xl, 24.0);
    expect(spacing.xxl, 32.0);
    expect(spacing.xxxl, 48.0);

    // Verify radius scale
    expect(radii.xs, 4.0);
    expect(radii.sm, 8.0);
    expect(radii.md, 12.0);
    expect(radii.lg, 16.0);
    expect(radii.xl, 24.0);
    expect(radii.full, 9999.0);

    // Verify shadow roles exist
    expect(shadows.soft, isNotEmpty);
    expect(shadows.medium, isNotEmpty);
    expect(shadows.strong, isNotEmpty);

    // Verify gradients exist
    expect(gradients.surfaceGradient, isNotNull);
    expect(gradients.accentGradient, isNotNull);
    expect(gradients.shimmerGradient, isNotNull);

    // Verify category colors exist
    expect(categories.core, isNotNull);
    expect(categories.upperArms, isNotNull);
    expect(categories.shoulders, isNotNull);
    expect(categories.back, isNotNull);
    expect(categories.chest, isNotNull);
    expect(categories.legs, isNotNull);
    expect(categories.cardio, isNotNull);
  });

  testWidgets('Dark theme includes all ThemeExtensions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.dark,
        home: const Scaffold(
          body: _TestWidget(),
        ),
      ),
    );

    final context = tester.element(find.byType(_TestWidget));
    final colors = context.themeExt<AppColors>();
    final typography = context.themeExt<AppTypography>();
    final spacing = context.themeExt<AppSpacing>();
    final radii = context.themeExt<AppRadii>();
    final shadows = context.themeExt<AppShadows>();
    final gradients = context.themeExt<AppGradients>();
    final categories = context.themeExt<AppCategoryColors>();

    expect(colors, isNotNull);
    expect(typography, isNotNull);
    expect(spacing, isNotNull);
    expect(radii, isNotNull);
    expect(shadows, isNotNull);
    expect(gradients, isNotNull);
    expect(categories, isNotNull);
  });
}

class _TestWidget extends StatelessWidget {
  const _TestWidget();

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
} 