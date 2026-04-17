import 'package:flutter/material.dart';
import '../theme.dart';
import 'app_tap_feedback.dart';

/// Design system list row/tile wrapper for consistent density and spacing.
class AppListRow extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool dense;

  const AppListRow({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.themeExt<AppSpacing>();
    final radii = context.themeExt<AppRadii>();

    final content = ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      titleAlignment: ListTileTitleAlignment.center,
      onTap: null,
      dense: dense,
      contentPadding: EdgeInsets.symmetric(
        horizontal: spacing.lg,
        vertical: dense ? spacing.sm : spacing.md,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radii.md),
      ),
    );

    return AppTapFeedback(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radii.md),
      child: content,
    );
  }
}

