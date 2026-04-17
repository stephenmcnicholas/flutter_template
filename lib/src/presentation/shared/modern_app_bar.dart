import 'package:flutter/material.dart';
import 'package:fytter/src/presentation/theme.dart';

class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? profileInitials;
  final String? profileImageUrl;
  final int? streakCount;
  final VoidCallback? onProfileTap;
  final Widget? leading;
  final List<Widget>? actions;

  const ModernAppBar({
    super.key,
    required this.title,
    this.profileInitials,
    this.profileImageUrl,
    this.streakCount,
    this.onProfileTap,
    this.leading,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.themeExt<AppColors>();
    final spacing = context.themeExt<AppSpacing>();
    final typography = context.themeExt<AppTypography>();
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return SafeArea(
      child: Container(
        color: colors.primary,
        padding: EdgeInsets.symmetric(horizontal: spacing.lg, vertical: spacing.sm),
        child: Row(
          children: [
            leading ??
                GestureDetector(
                  onTap: onProfileTap,
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: onPrimary,
                    backgroundImage: profileImageUrl != null && profileImageUrl!.isNotEmpty
                        ? NetworkImage(profileImageUrl!)
                        : null,
                    child: profileImageUrl != null && profileImageUrl!.isNotEmpty
                        ? null
                        : (profileInitials != null && profileInitials!.isNotEmpty)
                            ? Text(
                                profileInitials!,
                                style: TextStyle(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 20,
                                ),
                              )
                            : Icon(
                                Icons.person,
                                color: colors.primary,
                                size: 24,
                              ),
                  ),
                ),
            SizedBox(width: spacing.md),
            Expanded(
              child: Text(
                title,
                style: typography.title.copyWith(
                  color: onPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (actions != null) ...[
              SizedBox(width: spacing.md),
              ...actions!,
            ],
            if (streakCount != null) ...[
              SizedBox(width: spacing.md),
              _StreakWidget(
                count: streakCount!,
                textColor: onPrimary,
                iconColor: onPrimary,
                backgroundColor: onPrimary.withValues(alpha: 0.12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}

class _StreakWidget extends StatelessWidget {
  final int count;
  final Color textColor;
  final Color iconColor;
  final Color backgroundColor;
  const _StreakWidget({
    required this.count,
    required this.textColor,
    required this.iconColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.local_fire_department, color: iconColor, size: 20),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
} 