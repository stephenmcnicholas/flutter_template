import 'package:flutter/material.dart';

/// Standardized animation durations and curves for consistent motion.
class AppMotion {
  /// Fast animations (150ms) - for micro-interactions
  static const Duration fast = Duration(milliseconds: 150);

  /// Normal animations (300ms) - for most transitions
  static const Duration normal = Duration(milliseconds: 300);

  /// Slow animations (500ms) - for complex transitions
  static const Duration slow = Duration(milliseconds: 500);

  /// Standard easing curve for most transitions
  static const Curve standardCurve = Curves.easeInOut;

  /// Easing curve for entrances (ease out)
  static const Curve entranceCurve = Curves.easeOut;

  /// Easing curve for exits (ease in)
  static const Curve exitCurve = Curves.easeIn;

  /// Standard page transition duration
  static const Duration pageTransition = normal;

  /// Standard dialog/sheet transition duration
  static const Duration dialogTransition = normal;
}

