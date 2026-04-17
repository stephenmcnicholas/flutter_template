import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fytter/src/domain/program.dart';
import 'package:fytter/src/domain/session_check_in.dart';
import 'package:fytter/src/domain/workout_session.dart';
import 'package:fytter/src/presentation/shared/app_button.dart';
import 'package:fytter/src/presentation/shared/app_card.dart';
import 'package:fytter/src/presentation/shared/app_text.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/utils/program_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Route `extra` for [EndProgrammeReviewScreen].
class EndProgrammeReviewArgs {
  final String programId;
  final String programName;
  final int scheduledWorkouts;
  final int sessionsLogged;
  final double totalVolumeKg;
  final int totalSets;

  const EndProgrammeReviewArgs({
    required this.programId,
    required this.programName,
    required this.scheduledWorkouts,
    required this.sessionsLogged,
    required this.totalVolumeKg,
    required this.totalSets,
  });

  static String dismissedPrefsKey(String programId) => 'end_prog_review_done_$programId';
}

/// Block 3 Task 18: wrap-up before generating the next AI programme.
class EndProgrammeReviewScreen extends ConsumerStatefulWidget {
  final EndProgrammeReviewArgs args;

  const EndProgrammeReviewScreen({super.key, required this.args});

  @override
  ConsumerState<EndProgrammeReviewScreen> createState() => _EndProgrammeReviewScreenState();
}

class _EndProgrammeReviewScreenState extends ConsumerState<EndProgrammeReviewScreen> {
  CheckInRating _overall = CheckInRating.okay;
  final Set<String> _workedWell = {};
  final Set<String> _didntWork = {};
  final _notesController = TextEditingController();
  bool _isSaving = false;

  static const _workedOptions = [
    'Variety of lifts',
    'Progress felt real',
    'Recovery was fine',
    'Schedule fit life',
    'Enjoyed the focus',
  ];

  static const _didntOptions = [
    'Too much volume',
    'Too little challenge',
    'Scheduling clashes',
    'Joint or pain issues',
    'Bored / repetitive',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _markDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(EndProgrammeReviewArgs.dismissedPrefsKey(widget.args.programId), true);
  }

  String _buildLlmSummary() {
    final a = widget.args;
    final vol = a.totalVolumeKg >= 1000
        ? '${(a.totalVolumeKg / 1000).toStringAsFixed(1)}t'
        : '${a.totalVolumeKg.round()} kg';
    final overall = switch (_overall) {
      CheckInRating.great => 'Very positive',
      CheckInRating.okay => 'Mixed / OK',
      CheckInRating.tough => 'Challenging / tough',
      _ => 'OK',
    };
    final w = _workedWell.isEmpty ? '—' : _workedWell.join(', ');
    final d = _didntWork.isEmpty ? '—' : _didntWork.join(', ');
    final notes = _notesController.text.trim();
    return [
      'Completed AI programme "${a.programName}" (${a.scheduledWorkouts} scheduled sessions, '
          '${a.sessionsLogged} sessions logged in app, ~$vol volume, ${a.totalSets} sets).',
      'Overall: $overall.',
      'What worked: $w.',
      'What did not: $d.',
      if (notes.isNotEmpty) 'Own words: $notes',
    ].join(' ');
  }

  Future<void> _onLater() async {
    await _markDismissed();
    if (!mounted) return;
    context.pop();
  }

  Future<void> _onBuildNext() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final repo = ref.read(sessionCheckInRepositoryProvider);
    await repo.save(
      SessionCheckIn(
        id: const Uuid().v4(),
        sessionId: null,
        programmeId: widget.args.programId,
        checkInType: CheckInType.endProgramme,
        rating: _overall,
        freeText: _buildLlmSummary(),
        createdAt: DateTime.now(),
      ),
    );
    await _markDismissed();

    final summary = _buildLlmSummary();
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (!mounted) return;
    context.go('/ai-programme/create', extra: summary);
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.themeExt<AppSpacing>();
    final colors = context.themeExt<AppColors>();

    return Scaffold(
      appBar: AppBar(
        title: AppText('Programme complete', style: AppTextStyle.title),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(spacing.lg),
          children: [
            AppText(
              'Nice work finishing "${widget.args.programName}". '
              'A quick reflection helps your next programme fit you better.',
              style: AppTextStyle.body,
            ),
            SizedBox(height: spacing.lg),
            AppCard(
              padding: EdgeInsets.all(spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText('Your round-up', style: AppTextStyle.title),
                  SizedBox(height: spacing.sm),
                  AppText(
                    '${widget.args.scheduledWorkouts} sessions planned · '
                    '${widget.args.sessionsLogged} logged · '
                    '${widget.args.totalSets} sets · '
                    '~${widget.args.totalVolumeKg.round()} kg volume',
                    style: AppTextStyle.caption,
                  ),
                ],
              ),
            ),
            SizedBox(height: spacing.xl),
            AppText('How did it feel overall?', style: AppTextStyle.title),
            SizedBox(height: spacing.sm),
            SegmentedButton<CheckInRating>(
              segments: const [
                ButtonSegment(value: CheckInRating.great, label: Text('Great'), icon: Icon(Icons.mood)),
                ButtonSegment(value: CheckInRating.okay, label: Text('OK'), icon: Icon(Icons.sentiment_neutral)),
                ButtonSegment(value: CheckInRating.tough, label: Text('Tough'), icon: Icon(Icons.sentiment_dissatisfied)),
              ],
              selected: {_overall},
              onSelectionChanged: (s) => setState(() => _overall = s.first),
            ),
            SizedBox(height: spacing.xl),
            AppText('What worked?', style: AppTextStyle.title),
            SizedBox(height: spacing.sm),
            Wrap(
              spacing: spacing.sm,
              runSpacing: spacing.sm,
              children: [
                for (final label in _workedOptions)
                  FilterChip(
                    label: Text(label),
                    selected: _workedWell.contains(label),
                    onSelected: (v) => setState(() {
                      if (v) {
                        _workedWell.add(label);
                      } else {
                        _workedWell.remove(label);
                      }
                    }),
                  ),
              ],
            ),
            SizedBox(height: spacing.lg),
            AppText("What didn't?", style: AppTextStyle.title),
            SizedBox(height: spacing.sm),
            Wrap(
              spacing: spacing.sm,
              runSpacing: spacing.sm,
              children: [
                for (final label in _didntOptions)
                  FilterChip(
                    label: Text(label),
                    selected: _didntWork.contains(label),
                    onSelected: (v) => setState(() {
                      if (v) {
                        _didntWork.add(label);
                      } else {
                        _didntWork.remove(label);
                      }
                    }),
                  ),
              ],
            ),
            SizedBox(height: spacing.lg),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Anything else?',
                hintText: 'Optional — shared with your next programme build',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              maxLines: 4,
            ),
            SizedBox(height: spacing.xl),
            AppButton(
              label: 'Build my next programme',
              onPressed: _isSaving ? null : _onBuildNext,
              isFullWidth: true,
              isLoading: _isSaving,
            ),
            SizedBox(height: spacing.sm),
            TextButton(
              onPressed: _isSaving ? null : _onLater,
              child: AppText('Maybe later', style: AppTextStyle.label, color: colors.outline),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown on [ProgramDetailScreen] when an AI programme is fully completed and not dismissed.
class EndProgrammeCompletionBanner extends ConsumerStatefulWidget {
  final Program program;
  final Map<String, ProgramWorkoutStatus> statusByKey;
  final List<WorkoutSession> sessions;

  const EndProgrammeCompletionBanner({
    super.key,
    required this.program,
    required this.statusByKey,
    required this.sessions,
  });

  @override
  ConsumerState<EndProgrammeCompletionBanner> createState() => _EndProgrammeCompletionBannerState();
}

class _EndProgrammeCompletionBannerState extends ConsumerState<EndProgrammeCompletionBanner> {
  bool? _dismissed;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant EndProgrammeCompletionBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.program.id != widget.program.id) {
      _load();
    }
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getBool(EndProgrammeReviewArgs.dismissedPrefsKey(widget.program.id)) ?? false;
    if (mounted) setState(() => _dismissed = v);
  }

  Future<void> _openReview() async {
    final stats = programmeLoggedStats(widget.program, widget.sessions);
    await context.push<void>(
      '/programme/end-review',
      extra: EndProgrammeReviewArgs(
        programId: widget.program.id,
        programName: widget.program.name,
        scheduledWorkouts: widget.program.schedule.length,
        sessionsLogged: stats.sessionCount,
        totalVolumeKg: stats.totalVolumeKg,
        totalSets: stats.totalSets,
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.program.isAiGenerated ||
        !isProgramScheduleFullyCompleted(widget.program, widget.statusByKey)) {
      return const SizedBox.shrink();
    }
    if (_dismissed == null || _dismissed == true) {
      return const SizedBox.shrink();
    }

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
                Icon(Icons.emoji_events_outlined, color: colors.primary),
                SizedBox(width: spacing.sm),
                Expanded(
                  child: AppText(
                    'You finished this programme',
                    style: AppTextStyle.title,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.sm),
            AppText(
              'Tell us what worked and we will carry it into your next AI programme.',
              style: AppTextStyle.caption,
            ),
            SizedBox(height: spacing.md),
            AppButton(
              label: 'Review & plan next',
              onPressed: _openReview,
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}
