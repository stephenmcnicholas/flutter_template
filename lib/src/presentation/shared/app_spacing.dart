import 'package:flutter/material.dart';
import '../theme.dart';

/// Spacing/layout helpers using design system tokens.
class Insets {
  static EdgeInsets all(BuildContext context, double multiplier) {
    final spacing = context.themeExt<AppSpacing>();
    final value = spacing.lg * multiplier;
    return EdgeInsets.all(value);
  }

  static EdgeInsets symmetric(
    BuildContext context, {
    double? horizontal,
    double? vertical,
  }) {
    final spacing = context.themeExt<AppSpacing>();
    return EdgeInsets.symmetric(
      horizontal: (horizontal ?? 0) * spacing.lg,
      vertical: (vertical ?? 0) * spacing.lg,
    );
  }

  static EdgeInsets only(
    BuildContext context, {
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    final spacing = context.themeExt<AppSpacing>();
    return EdgeInsets.only(
      top: (top ?? 0) * spacing.lg,
      bottom: (bottom ?? 0) * spacing.lg,
      left: (left ?? 0) * spacing.lg,
      right: (right ?? 0) * spacing.lg,
    );
  }

  /// Direct access to spacing tokens
  static double xs(BuildContext context) =>
      context.themeExt<AppSpacing>().xs;
  static double sm(BuildContext context) =>
      context.themeExt<AppSpacing>().sm;
  static double md(BuildContext context) =>
      context.themeExt<AppSpacing>().md;
  static double lg(BuildContext context) =>
      context.themeExt<AppSpacing>().lg;
  static double xl(BuildContext context) =>
      context.themeExt<AppSpacing>().xl;
  static double xxl(BuildContext context) =>
      context.themeExt<AppSpacing>().xxl;
  static double xxxl(BuildContext context) =>
      context.themeExt<AppSpacing>().xxxl;
}

/// Spacer widgets with consistent sizing from design system.
class Gap extends StatelessWidget {
  final double multiplier;
  final Axis direction;

  const Gap({
    super.key,
    this.multiplier = 1.0,
    this.direction = Axis.vertical,
  });

  const Gap.horizontal({
    super.key,
    this.multiplier = 1.0,
  }) : direction = Axis.horizontal;

  const Gap.vertical({
    super.key,
    this.multiplier = 1.0,
  }) : direction = Axis.vertical;

  @override
  Widget build(BuildContext context) {
    final spacing = context.themeExt<AppSpacing>();
    final size = spacing.lg * multiplier;
    return direction == Axis.vertical
        ? SizedBox(height: size)
        : SizedBox(width: size);
  }
}

