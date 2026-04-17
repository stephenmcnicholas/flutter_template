import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/presentation/shared/app_text.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/providers/audio_providers.dart';

/// Modal shown when starting a workout (premium + guided). Shows session summary,
/// plays Template 1 (dynamic workout intro + X exercises, about X minutes, opening), "Ready to go" dismisses and triggers Template 2. Auto-dismisses after 30s.
class WorkoutIntroModal extends ConsumerStatefulWidget {
  const WorkoutIntroModal({
    super.key,
    this.workoutId,
    required this.exerciseCount,
    required this.durationMinutes,
    required this.firstExerciseId,
    required this.onDismiss,
  });

  /// Workout template ID for dynamic intro clip (slot 1). If null or file missing, slot 1 is skipped.
  final String? workoutId;
  final int exerciseCount;
  final int durationMinutes;
  final String? firstExerciseId;
  final VoidCallback onDismiss;

  @override
  ConsumerState<WorkoutIntroModal> createState() => _WorkoutIntroModalState();
}

class _WorkoutIntroModalState extends ConsumerState<WorkoutIntroModal> {
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _playTemplate1());
    _autoDismissTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) _dismiss();
    });
  }

  Future<void> _playTemplate1() async {
    try {
      final engine = ref.read(audioTemplateEngineProvider);
      final specs = engine.template1WorkoutIntro(
        workoutId: widget.workoutId,
        exerciseCount: widget.exerciseCount,
        durationMinutes: widget.durationMinutes,
      );
      final audio = ref.read(audioServiceProvider);
      await audio.playSequence(specs);
    } catch (_) {
      // Skip silently; audio is enhancement only
    }
  }

  void _dismiss() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;
    if (mounted) {
      Navigator.of(context).pop();
      widget.onDismiss();
    }
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.themeExt<AppSpacing>();
    final radii = context.themeExt<AppRadii>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radii.lg)),
      child: Padding(
        padding: EdgeInsets.all(spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppText('Session summary', style: AppTextStyle.title),
            SizedBox(height: spacing.md),
            AppText(
              '${widget.exerciseCount} exercise${widget.exerciseCount == 1 ? '' : 's'} · ~${widget.durationMinutes} min',
              style: AppTextStyle.body,
            ),
            SizedBox(height: spacing.xl),
            FilledButton(
              onPressed: _dismiss,
              child: const Text('Ready to go'),
            ),
          ],
        ),
      ),
    );
  }
}
