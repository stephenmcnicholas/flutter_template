import 'package:flutter/material.dart';
import '../theme.dart';

/// Design system divider with consistent color and thickness.
class AppDivider extends StatelessWidget {
  final double? indent;
  final double? endIndent;

  const AppDivider({
    super.key,
    this.indent,
    this.endIndent,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.themeExt<AppColors>();
    return Divider(
      height: 1,
      thickness: 1,
      color: colors.outline.withValues(alpha: 0.30),
      indent: indent,
      endIndent: endIndent,
    );
  }
}
