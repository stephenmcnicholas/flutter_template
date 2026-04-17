import 'package:flutter/material.dart';

/// Subtle staggered entry animation for list items.
class AppListEntryAnimation extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration duration;
  final int maxStaggerItems;

  const AppListEntryAnimation({
    super.key,
    required this.child,
    required this.index,
    this.duration = const Duration(milliseconds: 240),
    this.maxStaggerItems = 6,
  });

  @override
  State<AppListEntryAnimation> createState() => _AppListEntryAnimationState();
}

class _AppListEntryAnimationState extends State<AppListEntryAnimation> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    final clampedIndex =
        widget.index > widget.maxStaggerItems ? widget.maxStaggerItems : widget.index;
    final delay = Duration(milliseconds: 40 * clampedIndex);
    Future.delayed(delay, () {
      if (mounted) {
        setState(() => _visible = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: widget.duration,
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.04),
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
