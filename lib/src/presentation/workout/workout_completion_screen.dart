import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/presentation/shared/app_button.dart';
import 'package:fytter/src/presentation/shared/app_card.dart';
import 'package:fytter/src/presentation/shared/app_text.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/providers/audio_providers.dart';
import 'package:go_router/go_router.dart';

class WorkoutCompletionSummary {
  final String workoutName;
  final int exercisesCompleted;
  final int totalSets;
  final int totalReps;
  final double totalVolume;
  final Duration duration;
  /// When this workout was part of a program: program display name.
  final String? programName;
  /// When part of a program: number of workouts completed in that program (including this one).
  final int? workoutsCompletedInProgram;
  /// When part of a program: total number of workouts in the program.
  final int? totalWorkoutsInProgram;
  /// When part of a program: e.g. "Next: Upper body on Saturday" or "Rest before your next session."
  final String? nextWorkoutText;

  const WorkoutCompletionSummary({
    required this.workoutName,
    required this.exercisesCompleted,
    required this.totalSets,
    required this.totalReps,
    required this.totalVolume,
    required this.duration,
    this.programName,
    this.workoutsCompletedInProgram,
    this.totalWorkoutsInProgram,
    this.nextWorkoutText,
  });
}

class WorkoutCompletionScreen extends ConsumerStatefulWidget {
  final WorkoutCompletionSummary summary;

  const WorkoutCompletionScreen({
    super.key,
    required this.summary,
  });

  @override
  ConsumerState<WorkoutCompletionScreen> createState() =>
      _WorkoutCompletionScreenState();
}

class _WorkoutCompletionScreenState extends ConsumerState<WorkoutCompletionScreen>
    with TickerProviderStateMixin {
  late final AnimationController _celebrationController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final AnimationController _confettiController;
  late final List<_ConfettiParticle> _confetti;

  @override
  void initState() {
    super.initState();
    _playCelebration();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.8, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(_celebrationController);
    _fadeAnimation = CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.easeIn,
    );
    _celebrationController.forward();

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _confetti = _buildConfetti();
    _confettiController.forward();
  }

  Future<void> _playCelebration() async {
    // playPath extracts the bundle asset to a temp file and plays via
    // setFilePath — the same code path used by all coaching clips.
    await ref.read(audioServiceProvider).playPath('assets/audio/celebration.mp3');
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  List<_ConfettiParticle> _buildConfetti() {
    final random = math.Random(42);
    return List.generate(36, (index) {
      final angle = (math.pi * 2) * random.nextDouble();
      final speed = 60 + random.nextDouble() * 80;
      final radius = 3 + random.nextDouble() * 4;
      return _ConfettiParticle(
        angle: angle,
        speed: speed,
        radius: radius,
        colorIndex: index,
      );
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes == 0) {
      return '${seconds}s';
    }
    return '${minutes}m ${seconds}s';
  }

  String _formatVolume(double volume) {
    final rounded = volume.round();
    return '${rounded}kg';
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.themeExt<AppSpacing>();
    final colors = context.themeExt<AppColors>();
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final confettiColors = [
      colors.primary,
      colors.secondary,
      colors.success,
      colors.warning,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout complete'),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(spacing.lg),
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  children: [
                    SizedBox(
                      height: 160,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (!reduceMotion)
                            CustomPaint(
                              size: const Size(160, 160),
                              painter: _ConfettiPainter(
                                progress: _confettiController,
                                particles: _confetti,
                                colors: confettiColors,
                              ),
                            ),
                          Icon(
                            Icons.celebration,
                            size: 64,
                            color: colors.primary,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: spacing.md),
                    const AppText(
                      'Great work!',
                      style: AppTextStyle.headline,
                    ),
                    SizedBox(height: spacing.xs),
                    AppText(
                      widget.summary.workoutName,
                      style: AppTextStyle.caption,
                      color: colors.secondary,
                    ),
                    if (widget.summary.programName != null &&
                        widget.summary.workoutsCompletedInProgram != null &&
                        widget.summary.totalWorkoutsInProgram != null) ...[
                      SizedBox(height: spacing.md),
                      AppText(
                        "You're ${widget.summary.workoutsCompletedInProgram} of ${widget.summary.totalWorkoutsInProgram} workouts through ${widget.summary.programName}. Keep it up!",
                        style: AppTextStyle.body,
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (widget.summary.nextWorkoutText != null &&
                        widget.summary.nextWorkoutText!.trim().isNotEmpty) ...[
                      SizedBox(height: spacing.sm),
                      AppText(
                        widget.summary.nextWorkoutText!,
                        style: AppTextStyle.caption,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: spacing.xl),
            AppCard(
              child: Padding(
                padding: EdgeInsets.all(spacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppText(
                      'Summary',
                      style: AppTextStyle.title,
                    ),
                    SizedBox(height: spacing.md),
                    _StatRow(
                      label: 'Duration',
                      value: _formatDuration(widget.summary.duration),
                    ),
                    _StatRow(
                      label: 'Exercises',
                      value: widget.summary.exercisesCompleted.toString(),
                    ),
                    _StatRow(
                      label: 'Sets',
                      value: widget.summary.totalSets.toString(),
                    ),
                    _StatRow(
                      label: 'Reps',
                      value: widget.summary.totalReps.toString(),
                    ),
                    _StatRow(
                      label: 'Total volume',
                      value: _formatVolume(widget.summary.totalVolume),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: spacing.xl),
            AppButton(
              label: 'Done',
              isFullWidth: true,
              onPressed: () => context.go('/'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.themeExt<AppSpacing>();
    final colors = context.themeExt<AppColors>();

    return Padding(
      padding: EdgeInsets.only(bottom: spacing.sm),
      child: Row(
        children: [
          Expanded(
            child: AppText(
              label,
              style: AppTextStyle.body,
              color: colors.secondary,
            ),
          ),
          AppText(
            value,
            style: AppTextStyle.body,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }
}

class _ConfettiParticle {
  final double angle;
  final double speed;
  final double radius;
  final int colorIndex;

  const _ConfettiParticle({
    required this.angle,
    required this.speed,
    required this.radius,
    required this.colorIndex,
  });
}

class _ConfettiPainter extends CustomPainter {
  final Animation<double> progress;
  final List<_ConfettiParticle> particles;
  final List<Color> colors;

  _ConfettiPainter({
    required this.progress,
    required this.particles,
    required this.colors,
  }) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeOut.transform(progress.value);
    final center = Offset(size.width / 2, size.height / 2);
    for (final particle in particles) {
      final distance = particle.speed * t;
      final dx = math.cos(particle.angle) * distance;
      final dy = math.sin(particle.angle) * distance + (24 * t * t);
      final color = colors[particle.colorIndex % colors.length]
          .withValues(alpha: (1 - t).clamp(0.0, 1.0));
      final paint = Paint()..color = color;
      canvas.drawCircle(center.translate(dx, dy), particle.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.particles != particles ||
        oldDelegate.colors != colors;
  }
}
