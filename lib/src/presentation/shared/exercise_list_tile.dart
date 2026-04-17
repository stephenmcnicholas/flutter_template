import 'package:flutter/material.dart';
import 'package:fytter/src/presentation/shared/app_card.dart';
import 'package:fytter/src/presentation/shared/app_text.dart';
import 'package:fytter/src/presentation/shared/exercise_category_utils.dart';
import 'package:fytter/src/presentation/shared/exercise_media_widget.dart';
import 'package:fytter/src/presentation/theme.dart';

/// Consistent exercise tile used across list and selection screens.
class ExerciseListTile extends StatelessWidget {
  final String name;
  final String? bodyPart;
  final String? thumbnailPath;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool selected;
  final bool disabled;
  final double thumbnailSize;

  const ExerciseListTile({
    super.key,
    required this.name,
    required this.bodyPart,
    required this.thumbnailPath,
    this.trailing,
    this.onTap,
    this.selected = false,
    this.disabled = false,
    this.thumbnailSize = 64,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.themeExt<AppColors>();
    final spacing = context.themeExt<AppSpacing>();
    final radii = context.themeExt<AppRadii>();
    final categoryColor = categoryColorForBodyPart(context, bodyPart);

    Widget tile = AppCard(
      compact: true,
      onTap: disabled ? null : onTap,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: spacing.xs,
              decoration: BoxDecoration(
                color: categoryColor ?? colors.surface.withValues(alpha: 0),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(radii.lg),
                  bottomLeft: Radius.circular(radii.lg),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.lg,
                  vertical: spacing.sm,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: thumbnailSize,
                      height: thumbnailSize,
                      child: ExerciseMediaWidget(
                        assetPath: thumbnailPath,
                        isThumbnail: true,
                        thumbnailWidth: thumbnailSize,
                        thumbnailHeight: thumbnailSize,
                      ),
                    ),
                    SizedBox(width: spacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppText(name, style: AppTextStyle.label),
                          if (bodyPart != null)
                            AppText(bodyPart!, style: AppTextStyle.caption),
                        ],
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (selected) {
      tile = DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: colors.primary,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(radii.md),
        ),
        child: tile,
      );
    }

    if (disabled) {
      tile = Opacity(
        opacity: 0.5,
        child: tile,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radii.md),
      child: tile,
    );
  }
}
