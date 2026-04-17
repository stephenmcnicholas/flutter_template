import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/utils/haptic_utils.dart';
import '../theme.dart';

/// Shared tap feedback with scale + subtle overlay.
class AppTapFeedback extends ConsumerStatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final bool enableHaptics;
  final double pressedScale;

  const AppTapFeedback({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.enableHaptics = false,
    this.pressedScale = 0.98,
  });

  @override
  ConsumerState<AppTapFeedback> createState() => _AppTapFeedbackState();
}

class _AppTapFeedbackState extends ConsumerState<AppTapFeedback> {
  bool _isPressed = false;

  void _handleTap() {
    if (widget.enableHaptics) {
      ref.read(hapticsServiceProvider).light();
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.themeExt<AppColors>();

    return InkWell(
      onTap: widget.onTap == null ? null : _handleTap,
      borderRadius: widget.borderRadius,
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return colors.primary.withValues(alpha: 0.06);
        }
        return null;
      }),
      onHighlightChanged: (isHighlighted) {
        if (_isPressed != isHighlighted) {
          setState(() => _isPressed = isHighlighted);
        }
      },
      child: AnimatedScale(
        scale: _isPressed ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}
