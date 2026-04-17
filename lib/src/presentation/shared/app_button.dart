import 'package:flutter/material.dart';
import '../theme.dart';

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

/// Design system button with variants and states.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.themeExt<AppColors>();
    final spacing = context.themeExt<AppSpacing>();
    final radii = context.themeExt<AppRadii>();

    final isDisabled = onPressed == null || isLoading;

    Color backgroundColor;
    Color foregroundColor;
    Color? borderColor;

    switch (variant) {
      case AppButtonVariant.primary:
        backgroundColor = isDisabled
            ? _colorWithOpacity(colors.primary, 0.38)
            : colors.primary;
        foregroundColor = colors.surface;
        borderColor = null;
        break;
      case AppButtonVariant.secondary:
        backgroundColor = Colors.transparent;
        foregroundColor = colors.primary;
        borderColor = colors.primary;
        break;
      case AppButtonVariant.destructive:
        backgroundColor = isDisabled
            ? _colorWithOpacity(colors.error, 0.38)
            : colors.error;
        foregroundColor = colors.surface;
        borderColor = null;
        break;
    }

    final button = ElevatedButton(
      onPressed: isDisabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        side: borderColor != null
            ? BorderSide(color: borderColor, width: 1.5)
            : null,
        padding: EdgeInsets.symmetric(
          horizontal: spacing.xl,
          vertical: spacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.md),
        ),
        minimumSize: isFullWidth
            ? Size(double.infinity, 48)
            : const Size(0, 48), // Minimum tap target
      ),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  SizedBox(width: spacing.sm),
                ],
                Text(label),
              ],
            ),
    );

    return isFullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Button style variants.
enum AppButtonVariant {
  primary,
  secondary,
  destructive,
}

