import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fytter/src/presentation/shared/app_text.dart';
import 'package:fytter/src/presentation/theme.dart';

/// Arguments for the Let's go transition screen. Passed as route extra.
/// [args] is the workout context to pass back when popping so the caller can open the logger sheet.
class LetsGoTransitionArgs {
  final Object args;
  final String workoutName;
  final int durationMinutes;

  const LetsGoTransitionArgs({
    required this.args,
    required this.workoutName,
    required this.durationMinutes,
  });
}

/// Transition screen shown after check-in: workout name + estimated duration,
/// auto-advances after ~1.5s then pops with [LetsGoTransitionArgs.args].
class LetsGoTransitionScreen extends StatefulWidget {
  final LetsGoTransitionArgs transitionArgs;

  const LetsGoTransitionScreen({super.key, required this.transitionArgs});

  @override
  State<LetsGoTransitionScreen> createState() => _LetsGoTransitionScreenState();
}

class _LetsGoTransitionScreenState extends State<LetsGoTransitionScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      Navigator.of(context).pop(widget.transitionArgs.args);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.themeExt<AppSpacing>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(spacing.xxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText(
                  widget.transitionArgs.workoutName,
                  style: AppTextStyle.headline,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: spacing.lg),
                AppText(
                  '~${widget.transitionArgs.durationMinutes} min',
                  style: AppTextStyle.title,
                ),
                SizedBox(height: spacing.xl),
                AppText(
                  "Let's go",
                  style: AppTextStyle.body,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
