import 'package:flutter/material.dart';
import '../theme.dart';
import 'app_text.dart';

class AppStatItem {
  final String label;
  final String value;

  const AppStatItem({
    required this.label,
    required this.value,
  });
}

/// Consistent stats row for cards (2–3 columns).
class AppStatsRow extends StatelessWidget {
  final List<AppStatItem> items;

  const AppStatsRow({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.themeExt<AppSpacing>();
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final colorScheme = Theme.of(context).colorScheme;
    final radii = context.themeExt<AppRadii>();

    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      children.add(
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                item.label,
                style: AppTextStyle.caption,
                color: onSurface.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: spacing.xs),
              AppText(
                item.value,
                style: AppTextStyle.label,
                color: onSurface,
                fontWeight: FontWeight.w600,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
      if (i < items.length - 1) {
        children.add(SizedBox(width: spacing.md));
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.md,
        vertical: spacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(radii.md),
      ),
      child: Row(children: children),
    );
  }
}
