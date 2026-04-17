import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  test('Theme contrast meets WCAG AA targets for key pairs', () {
    _verifyThemeContrast(FytterTheme.light);
    _verifyThemeContrast(FytterTheme.dark);
  });
}

void _verifyThemeContrast(ThemeData theme) {
  final scheme = theme.colorScheme;
  final displayColor = theme.textTheme.displayLarge?.color ?? scheme.onSurface;
  final bodyColor = theme.textTheme.bodyLarge?.color ?? scheme.onSurface;
  final surface = scheme.surface;

  // Large text (display/headline/title) can meet 3.0:1.
  _expectContrast(displayColor, surface, 3.0, 'display/headline/title on surface');

  // Normal text (body/label/caption) must meet 4.5:1.
  _expectContrast(bodyColor, surface, 4.5, 'body/label/caption on surface');

  // Key semantic pairs typically used for buttons and alerts.
  _expectContrast(scheme.onPrimary, scheme.primary, 4.5, 'onPrimary/primary');
  _expectContrast(scheme.onSecondary, scheme.secondary, 4.5, 'onSecondary/secondary');
  _expectContrast(scheme.onError, scheme.error, 4.5, 'onError/error');
}

void _expectContrast(Color foreground, Color background, double minRatio, String label) {
  final ratio = _contrastRatio(foreground, background);
  expect(
    ratio >= minRatio,
    isTrue,
    reason: '$label contrast ${ratio.toStringAsFixed(2)}:1 is below $minRatio:1',
  );
}

double _contrastRatio(Color a, Color b) {
  final luminanceA = _relativeLuminance(a);
  final luminanceB = _relativeLuminance(b);
  final lighter = luminanceA > luminanceB ? luminanceA : luminanceB;
  final darker = luminanceA > luminanceB ? luminanceB : luminanceA;
  return (lighter + 0.05) / (darker + 0.05);
}

double _relativeLuminance(Color color) {
  double channel(double value) {
    final normalized = value / 255.0;
    return normalized <= 0.03928
        ? normalized / 12.92
        : math.pow((normalized + 0.055) / 1.055, 2.4) as double;
  }

  double component(double v) => (v * 255.0).round().clamp(0, 255).toDouble();
  final r = channel(component(color.r));
  final g = channel(component(color.g));
  final b = channel(component(color.b));
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}
