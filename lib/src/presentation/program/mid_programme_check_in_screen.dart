import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/data/programme_intensity_store.dart';
import 'package:fytter/src/domain/program.dart';
import 'package:fytter/src/domain/session_check_in.dart';
import 'package:fytter/src/domain/workout_session.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/presentation/shared/app_button.dart';
import 'package:fytter/src/presentation/shared/app_card.dart';
import 'package:fytter/src/presentation/shared/app_text.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/utils/program_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Route extra for [MidProgrammeCheckInScreen].
class MidProgrammeCheckInArgs {
  final String programId;
  final int milestone;

  const MidProgrammeCheckInArgs({
    required this.programId,
    required this.milestone,
  });

  static String prefsKey(String programId, int milestone) =>
      'mid_prog_check_done_${programId}_m$milestone';

  static Future<bool> isDismissed(String programId, int milestone) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefsKey(programId, milestone)) == true;
  }
}

/// Shown every 6 completed programme-linked sessions (Block 3 Task 17).
class MidProgrammeCheckInScreen extends ConsumerStatefulWidget {
  final MidProgrammeCheckInArgs args;

  const MidProgrammeCheckInScreen({super.key, required this.args});

  @override
  ConsumerState<MidProgrammeCheckInScreen> createState() =>
      _MidProgrammeCheckInScreenState();
}

class _MidProgrammeCheckInScreenState extends ConsumerState<MidProgrammeCheckInScreen> {
  CheckInRating? _selected;
  final _noteController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _markShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      MidProgrammeCheckInArgs.prefsKey(widget.args.programId, widget.args.milestone),
      true,
    );
  }

  Future<void> _saveAndPop(CheckInRating rating) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final repo = ref.read(sessionCheckInRepositoryProvider);
    final note = _noteController.text.trim();
    await repo.save(
      SessionCheckIn(
        id: const Uuid().v4(),
        sessionId: null,
        programmeId: widget.args.programId,
        checkInType: CheckInType.midProgramme,
        rating: rating,
        freeText: note.isNotEmpty ? note : null,
        createdAt: DateTime.now(),
      ),
    );
    await ProgrammeIntensityStore.applyMidProgrammeRating(widget.args.programId, rating);
    await _markShown();

    if (!mounted) return;
    setState(() => _isSaving = false);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _onSkip() async {
    await _markShown();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.themeExt<AppSpacing>();
    final colors = context.themeExt<AppColors>();

    return Scaffold(
      appBar: AppBar(
        title: AppText('Programme check-in', style: AppTextStyle.title),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _onSkip,
            child: AppText('Skip', style: AppTextStyle.label),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppText(
                "You've completed several sessions in this programme. How does it feel overall?",
                style: AppTextStyle.body,
              ),
              SizedBox(height: spacing.xl),
              _OptionTile(
                label: 'Too easy',
                subtitle: 'Ready for more challenge',
                color: colors.success,
                selected: _selected == CheckInRating.tooEasy,
                onTap: () => setState(() => _selected = CheckInRating.tooEasy),
              ),
              SizedBox(height: spacing.md),
              _OptionTile(
                label: 'About right',
                subtitle: 'Good balance for me',
                color: colors.outline,
                selected: _selected == CheckInRating.aboutRight,
                onTap: () => setState(() => _selected = CheckInRating.aboutRight),
              ),
              SizedBox(height: spacing.md),
              _OptionTile(
                label: 'Too hard',
                subtitle: 'Need to dial it back',
                color: colors.warning,
                selected: _selected == CheckInRating.tooHard,
                onTap: () => setState(() => _selected = CheckInRating.tooHard),
              ),
              if (_selected != null) ...[
                SizedBox(height: spacing.lg),
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    hintText: 'Anything else? (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: spacing.md),
                AppButton(
                  label: 'Save',
                  onPressed: _isSaving ? null : () => _saveAndPop(_selected!),
                  isFullWidth: true,
                  isLoading: _isSaving,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Programme detail card when a mid check-in milestone is due (every 6 logged sessions on this programme).
class MidProgrammeCheckInBanner extends StatefulWidget {
  final Program program;
  final Map<String, ProgramWorkoutStatus> statusByKey;
  final List<WorkoutSession> sessions;

  const MidProgrammeCheckInBanner({
    super.key,
    required this.program,
    required this.statusByKey,
    required this.sessions,
  });

  @override
  State<MidProgrammeCheckInBanner> createState() => _MidProgrammeCheckInBannerState();
}

class _MidProgrammeCheckInBannerState extends State<MidProgrammeCheckInBanner> {
  bool? _dismissed;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant MidProgrammeCheckInBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.program.id != widget.program.id) {
      _load();
      return;
    }
    final oldN = countSessionsForProgramSchedule(oldWidget.program, oldWidget.sessions);
    final newN = countSessionsForProgramSchedule(widget.program, widget.sessions);
    if (oldN != newN) {
      _load();
    }
  }

  Future<void> _load() async {
    final n = countSessionsForProgramSchedule(widget.program, widget.sessions);
    final milestone = midProgrammeMilestoneForSessionCount(n);
    if (milestone == null) {
      if (mounted) setState(() => _dismissed = true);
      return;
    }
    final dismissed = await MidProgrammeCheckInArgs.isDismissed(widget.program.id, milestone);
    if (mounted) setState(() => _dismissed = dismissed);
  }

  Future<void> _open() async {
    final n = countSessionsForProgramSchedule(widget.program, widget.sessions);
    final milestone = midProgrammeMilestoneForSessionCount(n);
    if (milestone == null) return;
    await context.push<void>(
      '/program/mid-check-in',
      extra: MidProgrammeCheckInArgs(programId: widget.program.id, milestone: milestone),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.program.schedule.isEmpty) return const SizedBox.shrink();
    final n = countSessionsForProgramSchedule(widget.program, widget.sessions);
    final milestone = midProgrammeMilestoneForSessionCount(n);
    if (milestone == null) return const SizedBox.shrink();
    if (widget.program.isAiGenerated &&
        isProgramScheduleFullyCompleted(widget.program, widget.statusByKey)) {
      return const SizedBox.shrink();
    }
    if (_dismissed == null || _dismissed == true) return const SizedBox.shrink();

    final spacing = context.themeExt<AppSpacing>();
    final colors = context.themeExt<AppColors>();

    return Padding(
      padding: EdgeInsets.only(bottom: spacing.md),
      child: AppCard(
        padding: EdgeInsets.all(spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.trending_flat, color: colors.primary),
                SizedBox(width: spacing.sm),
                Expanded(
                  child: AppText(
                    'Programme check-in',
                    style: AppTextStyle.title,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.sm),
            AppText(
              "You've logged $n sessions on this programme. How is the overall difficulty feeling?",
              style: AppTextStyle.caption,
            ),
            SizedBox(height: spacing.md),
            AppButton(
              label: 'Share feedback',
              onPressed: _open,
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.themeExt<AppSpacing>();
    final radii = context.themeExt<AppRadii>();

    return Material(
      color: selected ? color.withValues(alpha: 0.12) : null,
      borderRadius: BorderRadius.circular(radii.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radii.md),
        child: Padding(
          padding: EdgeInsets.all(spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(label, style: AppTextStyle.title),
              AppText(subtitle, style: AppTextStyle.caption),
            ],
          ),
        ),
      ),
    );
  }
}
