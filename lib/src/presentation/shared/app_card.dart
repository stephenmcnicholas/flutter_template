import 'package:flutter/material.dart';
import '../theme.dart';
import 'app_tap_feedback.dart';

/// Design system card with consistent styling.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double? elevation;
  final bool compact;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.elevation,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.themeExt<AppColors>();
    final spacing = context.themeExt<AppSpacing>();
    final radii = context.themeExt<AppRadii>();
    final shadows = context.themeExt<AppShadows>();

    // Compact mode uses reduced padding for list items
    final effectivePadding = padding ?? (compact 
        ? EdgeInsets.all(spacing.md) 
        : EdgeInsets.all(spacing.lg));

    final List<BoxShadow> effectiveShadows;
    if (elevation == null) {
      effectiveShadows = compact ? shadows.medium : shadows.strong;
    } else if (elevation! <= 1) {
      effectiveShadows = shadows.soft;
    } else if (elevation! <= 4) {
      effectiveShadows = shadows.medium;
    } else {
      effectiveShadows = shadows.strong;
    }

    final content = Padding(
      padding: effectivePadding,
      child: child,
    );

    final cardBody = Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(radii.lg),
      child: onTap == null
          ? content
          : AppTapFeedback(
              onTap: onTap,
              borderRadius: BorderRadius.circular(radii.lg),
              child: content,
            ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.lg),
        border: Border.all(
          color: colors.outline.withValues(alpha: 0.45),
          width: 1.2,
        ),
        boxShadow: effectiveShadows,
      ),
      child: cardBody,
    );
  }
}

