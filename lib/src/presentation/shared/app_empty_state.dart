import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme.dart';
import 'app_button.dart';
import 'app_text.dart';

/// Helper to create a color with opacity (compatible across Flutter versions).
// ignore: deprecated_member_use
Color _colorWithOpacity(Color color, double opacity) {
  return Color.fromRGBO(
    // ignore: deprecated_member_use
    color.red,
    // ignore: deprecated_member_use
    color.green,
    // ignore: deprecated_member_use
    color.blue,
    opacity,
  );
}

/// Standardized empty state widget.
class AppEmptyState extends StatelessWidget {
  final String title;
  final String? message;
  final IconData? icon;
  final String? illustrationAsset;
  final Color? illustrationColor;
  final double illustrationSize;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.illustrationAsset,
    this.illustrationColor,
    this.illustrationSize = 120,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.themeExt<AppColors>();
    final spacing = context.themeExt<AppSpacing>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final content = Center(
          child: Padding(
            padding: EdgeInsets.all(spacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (illustrationAsset != null) ...[
                  SvgPicture.asset(
                    illustrationAsset!,
                    width: illustrationSize,
                    height: illustrationSize,
                    colorFilter: ColorFilter.mode(
                      illustrationColor ?? colors.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                  SizedBox(height: spacing.xl),
                ] else if (icon != null) ...[
                  Icon(
                    icon,
                    size: 64,
                    color: _colorWithOpacity(colors.outline, 0.5),
                  ),
                  SizedBox(height: spacing.xl),
                ],
                AppText(
                  title,
                  style: AppTextStyle.headline,
                  textAlign: TextAlign.center,
                ),
                if (message != null) ...[
                  SizedBox(height: spacing.md),
                  AppText(
                    message!,
                    style: AppTextStyle.body,
                    textAlign: TextAlign.center,
                    color: colors.outline,
                  ),
                ],
                if (actionLabel != null && onAction != null) ...[
                  SizedBox(height: spacing.xl),
                  AppButton(
                    label: actionLabel!,
                    onPressed: onAction,
                    variant: AppButtonVariant.primary,
                  ),
                ],
              ],
            ),
          ),
        );

        if (!constraints.hasBoundedHeight) {
          return content;
        }

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: content,
          ),
        );
      },
    );
  }
}

