import 'package:flutter/material.dart';

/// Adds a subtle fade/slide to modal sheet content.
class AppSheetTransition extends StatelessWidget {
  final Widget child;
  final Curve curve;

  const AppSheetTransition({
    super.key,
    required this.child,
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null) {
      return child;
    }
    final curved = CurvedAnimation(parent: animation, curve: curve);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
