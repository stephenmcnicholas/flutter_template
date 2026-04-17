import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme.dart';

enum AppLoadingVariant {
  defaultView,
  list,
  card,
}

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

/// Loading state widget with optional shimmer skeleton.
class AppLoadingState extends StatelessWidget {
  final bool useShimmer;
  final String? message;
  final AppLoadingVariant variant;

  const AppLoadingState({
    super.key,
    this.useShimmer = false,
    this.message,
    this.variant = AppLoadingVariant.defaultView,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.themeExt<AppColors>();
    final spacing = context.themeExt<AppSpacing>();

    if (useShimmer) {
      final gradients = context.themeExt<AppGradients>();
      final shimmerColors = gradients.shimmerGradient.colors;
      final baseColor = shimmerColors.isNotEmpty
          ? shimmerColors.first
          : _colorWithOpacity(colors.surface, 0.3);
      final highlightColor = shimmerColors.length > 1
          ? shimmerColors[1]
          : _colorWithOpacity(colors.surface, 0.1);

      return Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: _buildShimmerLayout(spacing),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
          ),
          if (message != null) ...[
            SizedBox(height: spacing.lg),
            Text(
              message!,
              style: TextStyle(color: colors.outline),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShimmerLayout(AppSpacing spacing) {
    switch (variant) {
      case AppLoadingVariant.list:
        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            children: List.generate(
              6,
              (index) => Padding(
                padding: EdgeInsets.only(bottom: spacing.sm),
                child: _ShimmerBox(height: 64, width: double.infinity),
              ),
            ),
          ),
        );
      case AppLoadingVariant.card:
        return Column(
          children: [
            _ShimmerBox(height: 120, width: double.infinity),
            SizedBox(height: spacing.lg),
            _ShimmerBox(height: 16, width: double.infinity),
            SizedBox(height: spacing.sm),
            _ShimmerBox(height: 16, width: 200),
          ],
        );
      case AppLoadingVariant.defaultView:
        return Column(
          children: [
            _ShimmerBox(height: 200, width: double.infinity),
            SizedBox(height: spacing.lg),
            _ShimmerBox(height: 16, width: double.infinity),
            SizedBox(height: spacing.sm),
            _ShimmerBox(height: 16, width: 200),
          ],
        );
    }
  }
}

class _ShimmerBox extends StatelessWidget {
  final double height;
  final double width;

  const _ShimmerBox({
    required this.height,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.themeExt<AppColors>();
    final radii = context.themeExt<AppRadii>();
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.sm),
      ),
    );
  }
}

