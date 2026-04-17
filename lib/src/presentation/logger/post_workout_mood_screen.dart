import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/domain/session_check_in.dart';
import 'package:fytter/src/presentation/program/mid_programme_check_in_screen.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/scorecard_update_service.dart';
import 'package:fytter/src/utils/program_utils.dart';
import 'package:fytter/src/presentation/shared/app_card.dart';
import 'package:fytter/src/presentation/shared/app_text.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/presentation/workout/workout_completion_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

/// Arguments for the post-workout mood screen. Passed as route extra.
class PostWorkoutMoodArgs {
  final WorkoutCompletionSummary summary;
  final String? sessionId;
  final String? programId;
  /// Sessions logged for this programme's schedule, including the one just saved.
  final int? programCompletedSessionCount;

  /// Failed sets in the session just saved (for scorecard self-awareness).
  final int postWorkoutFailedSetCount;

  const PostWorkoutMoodArgs({
    required this.summary,
    this.sessionId,
    this.programId,
    this.programCompletedSessionCount,
    this.postWorkoutFailedSetCount = 0,
  });
}

class PostWorkoutMoodScreen extends ConsumerStatefulWidget {
  final PostWorkoutMoodArgs args;

  const PostWorkoutMoodScreen({super.key, required this.args});

  @override
  ConsumerState<PostWorkoutMoodScreen> createState() =>
      _PostWorkoutMoodScreenState();
}

class _PostWorkoutMoodScreenState extends ConsumerState<PostWorkoutMoodScreen> {
  bool _isSaving = false;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String? get _note =>
      _noteController.text.trim().isEmpty ? null : _noteController.text.trim();

  Future<void> _saveAndProceed(CheckInRating rating) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final repo = ref.read(sessionCheckInRepositoryProvider);
    final checkIn = SessionCheckIn(
      id: const Uuid().v4(),
      sessionId: widget.args.sessionId,
      programmeId: widget.args.programId,
      checkInType: CheckInType.postSession,
      rating: rating,
      freeText: _note,
      createdAt: DateTime.now(),
    );
    await repo.save(checkIn);

    final weakVsMood = (rating == CheckInRating.great ||
            rating == CheckInRating.okay) &&
        widget.args.postWorkoutFailedSetCount >= 2;
    await ref.read(scorecardUpdateServiceProvider).onPostWorkoutCheckIn(
          rating: rating,
          performanceWasWeakerThanCheckIn: weakVsMood,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);
    if (!mounted) return;
    await _maybeMidProgrammeThenCompletion();
  }

  Future<void> _onSkip() async {
    await _maybeMidProgrammeThenCompletion();
  }

  Future<void> _maybeMidProgrammeThenCompletion() async {
    final pid = widget.args.programId;
    final n = widget.args.programCompletedSessionCount;
    final milestone =
        n != null && n > 0 ? midProgrammeMilestoneForSessionCount(n) : null;
    if (pid != null && pid.isNotEmpty && milestone != null) {
      if (!await MidProgrammeCheckInArgs.isDismissed(pid, milestone) && mounted) {
        await context.push<void>(
          '/program/mid-check-in',
          extra: MidProgrammeCheckInArgs(programId: pid, milestone: milestone),
        );
      }
    }
    if (!mounted) return;
    context.push('/workout/completion', extra: widget.args.summary);
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.themeExt<AppSpacing>();
    final colors = context.themeExt<AppColors>();

    return Scaffold(
      backgroundColor: Colors.black54,
      body: SafeArea(
        child: GestureDetector(
          onTap: _isSaving ? null : _onSkip,
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing.xl),
                child: AppCard(
                  padding: EdgeInsets.all(spacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText('How was it?', style: AppTextStyle.title),
                          TextButton(
                            onPressed: _isSaving ? null : _onSkip,
                            child: AppText('Skip', style: AppTextStyle.label),
                          ),
                        ],
                      ),
                      SizedBox(height: spacing.sm),
                      AppText(
                        'Quick tap — helps us tailor your experience next time.',
                        style: AppTextStyle.body,
                      ),
                      SizedBox(height: spacing.lg),
                      TextField(
                        controller: _noteController,
                        enabled: !_isSaving,
                        decoration: InputDecoration(
                          hintText: 'Optional note',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        maxLines: 2,
                      ),
                      SizedBox(height: spacing.lg),
                      _MoodOption(
                        emoji: '💪',
                        label: 'Strong',
                        color: colors.success,
                        onTap: () => _saveAndProceed(CheckInRating.great),
                        enabled: !_isSaving,
                      ),
                      SizedBox(height: spacing.md),
                      _MoodOption(
                        emoji: '😐',
                        label: 'OK',
                        color: colors.outline,
                        onTap: () => _saveAndProceed(CheckInRating.okay),
                        enabled: !_isSaving,
                      ),
                      SizedBox(height: spacing.md),
                      _MoodOption(
                        emoji: '😓',
                        label: 'Tough',
                        color: colors.warning,
                        onTap: () => _saveAndProceed(CheckInRating.tough),
                        enabled: !_isSaving,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoodOption extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;

  const _MoodOption({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.themeExt<AppSpacing>();
    final radii = context.themeExt<AppRadii>();

    return Material(
      color: enabled ? color.withValues(alpha: 0.12) : null,
      borderRadius: BorderRadius.circular(radii.md),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(radii.md),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: spacing.lg, horizontal: spacing.lg),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              SizedBox(width: spacing.md),
              AppText(label, style: AppTextStyle.title),
            ],
          ),
        ),
      ),
    );
  }
}
