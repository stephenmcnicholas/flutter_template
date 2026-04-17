import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized theming for Fytter.
class FytterTheme {
  static String? _fontFamily() {
    // Avoid runtime fetches when disabled (e.g., tests/offline).
    if (GoogleFonts.config.allowRuntimeFetching == false) {
      return null;
    }
    try {
      return GoogleFonts.inter().fontFamily;
    } catch (e) {
      // If font loading fails (e.g., during hot reload or missing assets),
      // fall back to system font
      debugPrint('Warning: Failed to load Google Fonts, using system font: $e');
      return null;
    }
  }

  /// Light theme configuration.
  static ThemeData get light {
    final baseTheme = FlexThemeData.light(
      colors: const FlexSchemeColor(
        primary: Color(0xFFD32F2F),
        primaryContainer: Color(0xFFFFCDD2),
        secondary: Color(0xFF263238),
        secondaryContainer: Color(0xFFCFD8DC),
      ),
      useMaterial3: true,
      fontFamily: _fontFamily(),
    );
    return baseTheme.copyWith(
      tabBarTheme: TabBarThemeData(
        labelColor: baseTheme.colorScheme.primary,
        unselectedLabelColor: baseTheme.colorScheme.outline,
        labelStyle: baseTheme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        indicatorSize: TabBarIndicatorSize.label,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            color: baseTheme.colorScheme.primary,
            width: 3,
          ),
          insets: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[
        AppColors.light(baseTheme.colorScheme),
        AppTypography.light(baseTheme.textTheme),
        AppSpacing.light,
        AppRadii.light,
        AppShadows.light(baseTheme.colorScheme),
        AppGradients.light(baseTheme.colorScheme),
        AppCategoryColors.light(),
      ],
    );
  }

  /// Dark theme configuration.
  static ThemeData get dark {
    final baseTheme = FlexThemeData.dark(
      colors: const FlexSchemeColor(
        primary: Color(0xFFEF5350),
        primaryContainer: Color(0xFFB71C1C),
        secondary: Color(0xFFB0BEC5),
        secondaryContainer: Color(0xFF37474F),
      ),
      useMaterial3: true,
      fontFamily: _fontFamily(),
    );
    final colorScheme = baseTheme.colorScheme.copyWith(
      onPrimary: const Color(0xFF000000),
    );
    return baseTheme.copyWith(
      colorScheme: colorScheme,
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.outline,
        labelStyle: baseTheme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        indicatorSize: TabBarIndicatorSize.label,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 3,
          ),
          insets: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[
        AppColors.dark(colorScheme),
        AppTypography.dark(baseTheme.textTheme),
        AppSpacing.dark,
        AppRadii.dark,
        AppShadows.dark(colorScheme),
        AppGradients.dark(colorScheme),
        AppCategoryColors.dark(),
      ],
    );
  }
}

/// Shadow system for consistent elevation depth beyond Material defaults.
@immutable
class AppShadows extends ThemeExtension<AppShadows> {
  final List<BoxShadow> soft;
  final List<BoxShadow> medium;
  final List<BoxShadow> strong;

  const AppShadows({
    required this.soft,
    required this.medium,
    required this.strong,
  });

  static AppShadows light(ColorScheme colorScheme) {
    final base = colorScheme.shadow;
    return AppShadows(
      soft: [
        BoxShadow(
          color: base.withValues(alpha: 0.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      medium: [
        BoxShadow(
          color: base.withValues(alpha: 0.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: base.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
      strong: [
        BoxShadow(
          color: base.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: base.withValues(alpha: 0.10),
          blurRadius: 32,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static AppShadows dark(ColorScheme colorScheme) {
    final base = colorScheme.shadow;
    return AppShadows(
      soft: [
        BoxShadow(
          color: base.withValues(alpha: 0.10),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      medium: [
        BoxShadow(
          color: base.withValues(alpha: 0.10),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: base.withValues(alpha: 0.18),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
      strong: [
        BoxShadow(
          color: base.withValues(alpha: 0.18),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: base.withValues(alpha: 0.26),
          blurRadius: 32,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  @override
  AppShadows copyWith({
    List<BoxShadow>? soft,
    List<BoxShadow>? medium,
    List<BoxShadow>? strong,
  }) {
    return AppShadows(
      soft: soft ?? this.soft,
      medium: medium ?? this.medium,
      strong: strong ?? this.strong,
    );
  }

  @override
  AppShadows lerp(ThemeExtension<AppShadows>? other, double t) {
    if (other is! AppShadows) {
      return this;
    }
    return AppShadows(
      soft: _lerpShadows(soft, other.soft, t),
      medium: _lerpShadows(medium, other.medium, t),
      strong: _lerpShadows(strong, other.strong, t),
    );
  }

  List<BoxShadow> _lerpShadows(
    List<BoxShadow> a,
    List<BoxShadow> b,
    double t,
  ) {
    final length = a.length < b.length ? a.length : b.length;
    return List<BoxShadow>.generate(
      length,
      (index) => BoxShadow.lerp(a[index], b[index], t)!,
    );
  }
}

/// Gradient system for subtle depth and highlight effects.
@immutable
class AppGradients extends ThemeExtension<AppGradients> {
  final Gradient surfaceGradient;
  final Gradient? backgroundGradient;
  final Gradient accentGradient;
  final Gradient shimmerGradient;

  const AppGradients({
    required this.surfaceGradient,
    required this.backgroundGradient,
    required this.accentGradient,
    required this.shimmerGradient,
  });

  static AppGradients light(ColorScheme colorScheme) {
    final surface = colorScheme.surface;
    final background = colorScheme.surface;
    final primary = colorScheme.primary;
    return AppGradients(
      surfaceGradient: LinearGradient(
        colors: [
          surface,
          surface.withValues(alpha: 0.94),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      backgroundGradient: LinearGradient(
        colors: [
          background,
          background.withValues(alpha: 0.96),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      accentGradient: LinearGradient(
        colors: [
          primary,
          primary.withValues(alpha: 0.90),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      shimmerGradient: LinearGradient(
        colors: [
          colorScheme.surfaceContainerHighest.withValues(alpha: 0.70),
          colorScheme.surfaceContainerHighest.withValues(alpha: 0.30),
          colorScheme.surfaceContainerHighest.withValues(alpha: 0.70),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
    );
  }

  static AppGradients dark(ColorScheme colorScheme) {
    final surface = colorScheme.surface;
    final background = colorScheme.surface;
    final primary = colorScheme.primary;
    return AppGradients(
      surfaceGradient: LinearGradient(
        colors: [
          surface,
          surface.withValues(alpha: 0.92),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      backgroundGradient: LinearGradient(
        colors: [
          background,
          background.withValues(alpha: 0.94),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      accentGradient: LinearGradient(
        colors: [
          primary,
          primary.withValues(alpha: 0.85),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      shimmerGradient: LinearGradient(
        colors: [
          colorScheme.surfaceContainerHighest.withValues(alpha: 0.60),
          colorScheme.surfaceContainerHighest.withValues(alpha: 0.30),
          colorScheme.surfaceContainerHighest.withValues(alpha: 0.60),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
    );
  }

  @override
  AppGradients copyWith({
    Gradient? surfaceGradient,
    Gradient? backgroundGradient,
    Gradient? accentGradient,
    Gradient? shimmerGradient,
  }) {
    return AppGradients(
      surfaceGradient: surfaceGradient ?? this.surfaceGradient,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      accentGradient: accentGradient ?? this.accentGradient,
      shimmerGradient: shimmerGradient ?? this.shimmerGradient,
    );
  }

  @override
  AppGradients lerp(ThemeExtension<AppGradients>? other, double t) {
    if (other is! AppGradients) {
      return this;
    }
    return AppGradients(
      surfaceGradient: Gradient.lerp(surfaceGradient, other.surfaceGradient, t)!,
      backgroundGradient: backgroundGradient == null && other.backgroundGradient == null
          ? null
          : Gradient.lerp(backgroundGradient, other.backgroundGradient, t),
      accentGradient: Gradient.lerp(accentGradient, other.accentGradient, t)!,
      shimmerGradient: Gradient.lerp(shimmerGradient, other.shimmerGradient, t)!,
    );
  }
}

/// Category color mapping for exercise groups.
@immutable
class AppCategoryColors extends ThemeExtension<AppCategoryColors> {
  final Color core;
  final Color upperArms;
  final Color shoulders;
  final Color back;
  final Color chest;
  final Color legs;
  final Color cardio;

  const AppCategoryColors({
    required this.core,
    required this.upperArms,
    required this.shoulders,
    required this.back,
    required this.chest,
    required this.legs,
    required this.cardio,
  });

  static AppCategoryColors light() {
    return const AppCategoryColors(
      core: Colors.orange,
      upperArms: Colors.blue,
      shoulders: Colors.purple,
      back: Colors.green,
      chest: Colors.red,
      legs: Colors.amber,
      cardio: Colors.teal,
    );
  }

  static AppCategoryColors dark() {
    return const AppCategoryColors(
      core: Colors.orangeAccent,
      upperArms: Colors.lightBlueAccent,
      shoulders: Colors.deepPurpleAccent,
      back: Colors.lightGreenAccent,
      chest: Colors.redAccent,
      legs: Colors.amberAccent,
      cardio: Colors.tealAccent,
    );
  }

  @override
  AppCategoryColors copyWith({
    Color? core,
    Color? upperArms,
    Color? shoulders,
    Color? back,
    Color? chest,
    Color? legs,
    Color? cardio,
  }) {
    return AppCategoryColors(
      core: core ?? this.core,
      upperArms: upperArms ?? this.upperArms,
      shoulders: shoulders ?? this.shoulders,
      back: back ?? this.back,
      chest: chest ?? this.chest,
      legs: legs ?? this.legs,
      cardio: cardio ?? this.cardio,
    );
  }

  @override
  AppCategoryColors lerp(ThemeExtension<AppCategoryColors>? other, double t) {
    if (other is! AppCategoryColors) {
      return this;
    }
    return AppCategoryColors(
      core: Color.lerp(core, other.core, t)!,
      upperArms: Color.lerp(upperArms, other.upperArms, t)!,
      shoulders: Color.lerp(shoulders, other.shoulders, t)!,
      back: Color.lerp(back, other.back, t)!,
      chest: Color.lerp(chest, other.chest, t)!,
      legs: Color.lerp(legs, other.legs, t)!,
      cardio: Color.lerp(cardio, other.cardio, t)!,
    );
  }
}

/// Color roles for semantic color usage.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color primary;
  final Color secondary;
  final Color surface;
  final Color background;
  final Color error;
  final Color success;
  final Color warning;
  final Color outline;

  const AppColors({
    required this.primary,
    required this.secondary,
    required this.surface,
    required this.background,
    required this.error,
    required this.success,
    required this.warning,
    required this.outline,
  });

  static AppColors light(ColorScheme colorScheme) {
    return AppColors(
      primary: colorScheme.primary,
      secondary: colorScheme.secondary,
      surface: colorScheme.surface,
      background: colorScheme.surface,
      error: colorScheme.error,
      success: const Color(0xFF4CAF50), // Material green
      warning: const Color(0xFFFF9800), // Material orange
      outline: colorScheme.outline,
    );
  }

  static AppColors dark(ColorScheme colorScheme) {
    return AppColors(
      primary: colorScheme.primary,
      secondary: colorScheme.secondary,
      surface: colorScheme.surface,
      background: colorScheme.surface,
      error: colorScheme.error,
      success: const Color(0xFF66BB6A), // Lighter green for dark theme
      warning: const Color(0xFFFFB74D), // Lighter orange for dark theme
      outline: colorScheme.outline,
    );
  }

  @override
  AppColors copyWith({
    Color? primary,
    Color? secondary,
    Color? surface,
    Color? background,
    Color? error,
    Color? success,
    Color? warning,
    Color? outline,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      surface: surface ?? this.surface,
      background: background ?? this.background,
      error: error ?? this.error,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      outline: outline ?? this.outline,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      background: Color.lerp(background, other.background, t)!,
      error: Color.lerp(error, other.error, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
    );
  }
}

/// Typography roles for semantic text styling.
@immutable
class AppTypography extends ThemeExtension<AppTypography> {
  final TextStyle display;
  final TextStyle headline;
  final TextStyle title;
  final TextStyle body;
  final TextStyle label;
  final TextStyle caption;

  const AppTypography({
    required this.display,
    required this.headline,
    required this.title,
    required this.body,
    required this.label,
    required this.caption,
  });

  static AppTypography light(TextTheme textTheme) {
    return AppTypography(
      display: textTheme.displayLarge?.copyWith(
            fontSize: 32,
            fontWeight: FontWeight.w600,
          ) ??
          const TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
      headline: textTheme.headlineMedium?.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ) ??
          const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
      title: textTheme.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ) ??
          const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      body: textTheme.bodyLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ) ??
          const TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
      label: textTheme.labelLarge?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ) ??
          const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      caption: textTheme.bodySmall?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.normal,
          ) ??
          const TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
    );
  }

  static AppTypography dark(TextTheme textTheme) {
    return AppTypography.light(textTheme);
  }

  @override
  AppTypography copyWith({
    TextStyle? display,
    TextStyle? headline,
    TextStyle? title,
    TextStyle? body,
    TextStyle? label,
    TextStyle? caption,
  }) {
    return AppTypography(
      display: display ?? this.display,
      headline: headline ?? this.headline,
      title: title ?? this.title,
      body: body ?? this.body,
      label: label ?? this.label,
      caption: caption ?? this.caption,
    );
  }

  @override
  AppTypography lerp(ThemeExtension<AppTypography>? other, double t) {
    if (other is! AppTypography) {
      return this;
    }
    return AppTypography(
      display: TextStyle.lerp(display, other.display, t)!,
      headline: TextStyle.lerp(headline, other.headline, t)!,
      title: TextStyle.lerp(title, other.title, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      label: TextStyle.lerp(label, other.label, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
    );
  }
}

/// Spacing scale for consistent margins and padding.
@immutable
class AppSpacing extends ThemeExtension<AppSpacing> {
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;
  final double xxxl;

  const AppSpacing({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
    required this.xxxl,
  });

  static const AppSpacing light = AppSpacing(
    xs: 4.0,
    sm: 8.0,
    md: 12.0,
    lg: 16.0,
    xl: 24.0,
    xxl: 32.0,
    xxxl: 48.0,
  );

  static const AppSpacing dark = AppSpacing.light;

  @override
  AppSpacing copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
    double? xxxl,
  }) {
    return AppSpacing(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
      xxxl: xxxl ?? this.xxxl,
    );
  }

  @override
  AppSpacing lerp(ThemeExtension<AppSpacing>? other, double t) {
    if (other is! AppSpacing) {
      return this;
    }
    return AppSpacing(
      xs: xs + (other.xs - xs) * t,
      sm: sm + (other.sm - sm) * t,
      md: md + (other.md - md) * t,
      lg: lg + (other.lg - lg) * t,
      xl: xl + (other.xl - xl) * t,
      xxl: xxl + (other.xxl - xxl) * t,
      xxxl: xxxl + (other.xxxl - xxxl) * t,
    );
  }
}

/// Border radius scale for consistent corner rounding.
@immutable
class AppRadii extends ThemeExtension<AppRadii> {
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double full;

  const AppRadii({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.full,
  });

  static const AppRadii light = AppRadii(
    xs: 4.0,
    sm: 8.0,
    md: 12.0,
    lg: 16.0,
    xl: 24.0,
    full: 9999.0,
  );

  static const AppRadii dark = AppRadii.light;

  @override
  AppRadii copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? full,
  }) {
    return AppRadii(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      full: full ?? this.full,
    );
  }

  @override
  AppRadii lerp(ThemeExtension<AppRadii>? other, double t) {
    if (other is! AppRadii) {
      return this;
    }
    return AppRadii(
      xs: xs + (other.xs - xs) * t,
      sm: sm + (other.sm - sm) * t,
      md: md + (other.md - md) * t,
      lg: lg + (other.lg - lg) * t,
      xl: xl + (other.xl - xl) * t,
      full: full + (other.full - full) * t,
    );
  }
}

/// Convenience extension for accessing ThemeExtensions.
extension ThemeExtensionHelper on BuildContext {
  T themeExt<T extends ThemeExtension<T>>() {
    return Theme.of(this).extension<T>()!;
  }
}