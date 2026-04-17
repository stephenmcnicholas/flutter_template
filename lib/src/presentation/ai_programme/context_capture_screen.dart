import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/utils/haptic_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fytter/src/data/programme_generation_service.dart';
import 'package:fytter/src/domain/user_profile.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/programme_generation_provider.dart';
import 'package:fytter/src/providers/user_profile_provider.dart';
import 'package:fytter/src/providers/user_scorecard_provider.dart';
import 'package:fytter/src/presentation/shared/app_button.dart';
import 'package:fytter/src/presentation/shared/app_card.dart';
import 'package:fytter/src/presentation/shared/app_text.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/presentation/ai_programme/ai_programme_strings.dart';

enum _StepId {
  intro,
  goal,
  days,
  blockedDays,
  sessionLength,
  equipment,
  experience,
  age,
  injuries,
  additional,
  startDate,
  done,
}

/// Multi-step context capture for AI programme generation. Pre-fills from profile.
///
/// [previousProgrammeSummary] is set when navigating from end-of-programme review
/// (route `extra` on `/ai-programme/create`) and passed to the LLM as prior context.
class ContextCaptureScreen extends ConsumerStatefulWidget {
  const ContextCaptureScreen({super.key, this.previousProgrammeSummary});

  final String? previousProgrammeSummary;

  @override
  ConsumerState<ContextCaptureScreen> createState() => _ContextCaptureScreenState();
}

class _ContextCaptureScreenState extends ConsumerState<ContextCaptureScreen> {
  int _stepIndex = 0;
  String _goal = 'general_fitness';
  int _daysPerWeek = 3;
  final Set<String> _blockedDays = {};
  int _sessionLengthMinutes = 45;
  String _equipment = 'full_gym';
  /// "never" | "some" | "regular"; null = not specified (do not assume beginner in copy).
  String? _experienceLevel;
  int? _age;
  String _injuries = '';
  /// Side selections per bilateral body part: 'left' | 'right' | 'both'.
  final Map<String, String?> _injurySides = {};
  String _additionalContext = '';
  DateTime _programStartDate = _nextMonday(DateTime.now());
  final _injuriesController = TextEditingController();
  final _additionalController = TextEditingController();
  bool _profileApplied = false;
  late FixedExtentScrollController _ageScrollController;

  static const int _kMinAge = 16;
  static const int _kMaxAge = 80;
  static const int _kDefaultAge = 25;

  static DateTime _nextMonday(DateTime from) {
    final today = DateTime(from.year, from.month, from.day);
    final weekday = today.weekday;
    final daysUntilMonday = weekday == DateTime.monday ? 0 : (8 - weekday) % 7;
    return today.add(Duration(days: daysUntilMonday));
  }

  /// Body parts that are bilateral and benefit from a left/right/both follow-up.
  static const List<String> _bilateralParts = [
    'shoulder', 'knee', 'elbow', 'hip', 'wrist', 'ankle',
  ];

  /// Returns true if [part] appears in [text] in a clause that does NOT already
  /// contain a side indicator (left / right / both), so we know to ask which side.
  /// Clauses are split on sentence-end and list punctuation.
  static bool _partNeedsSideFollowUp(String text, String part) {
    final lower = text.toLowerCase();
    if (!lower.contains(part)) return false;
    final clauses = lower.split(RegExp(r'[.,;!?\n]+'));
    const sidePattern = r'\b(left|right|both)\b';
    for (final clause in clauses) {
      if (clause.contains(part) && !RegExp(sidePattern).hasMatch(clause)) {
        return true;
      }
    }
    return false;
  }

  static const List<_StepId> _steps = [
    _StepId.intro,
    _StepId.goal,
    _StepId.days,
    _StepId.blockedDays,
    _StepId.sessionLength,
    _StepId.equipment,
    _StepId.experience,
    _StepId.age,
    _StepId.injuries,
    _StepId.additional,
    _StepId.startDate,
    _StepId.done,
  ];

  /// Number of "question" steps for progress bar (intro does not count).
  static const int _progressSteps = 11;

  @override
  void initState() {
    super.initState();
    _ageScrollController = FixedExtentScrollController(
      initialItem: _kDefaultAge - _kMinAge,
    );
  }

  @override
  void dispose() {
    _ageScrollController.dispose();
    _injuriesController.dispose();
    _additionalController.dispose();
    super.dispose();
  }

  _StepId get _currentStep => _steps[_stepIndex];
  int get _totalSteps => _steps.length;

  void _next() {
    if (_stepIndex < _totalSteps - 1) {
      setState(() {
        final nextIndex = _stepIndex + 1;
        if (_steps[nextIndex] == _StepId.blockedDays) {
          final suggested = _suggestedDaysFor(_daysPerWeek);
          _blockedDays.clear();
          _blockedDays.addAll(_weekdays.where((d) => !suggested.contains(d)));
        }
        _stepIndex = nextIndex;
      });
    }
  }

  void _back() {
    if (_stepIndex > 0) {
      setState(() => _stepIndex--);
    }
  }

  void _applyProfileOnce(UserProfile? profile) {
    if (profile == null || _profileApplied) return;
    _profileApplied = true;
    _goal = primaryGoalToStorage(profile.primaryGoal);
    _daysPerWeek = profile.daysPerWeek;
    _sessionLengthMinutes = profile.sessionLengthMinutes;
    _equipment = _equipmentFromProfile(profile.equipment);
    _experienceLevel = experienceLevelToStorage(profile.experienceLevel);
    _injuries = profile.injuriesNotes ?? '';
    _age = profile.age;
    _blockedDays.addAll(profile.blockedDays ?? []);
    _injuriesController.text = _injuries;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
        if (profile.age != null) {
          final item = (profile.age! - _kMinAge).clamp(0, _kMaxAge - _kMinAge);
          _ageScrollController.jumpToItem(item);
        }
      }
    });
  }

  static String _equipmentFromProfile(EquipmentAccess e) {
    switch (e) {
      case EquipmentAccess.fullGym:
        return 'full_gym';
      case EquipmentAccess.bodyweightOnly:
        return 'bodyweight';
      case EquipmentAccess.homeDumbbells:
        return 'home';
    }
  }

  Future<void> _generate() async {
    final exercises = await ref.read(exercisesFutureProvider.future);
    if (exercises.isEmpty) return;
    ref.read(pendingProgrammeSummaryProvider.notifier).state = (days: _daysPerWeek, goalLabel: _goalLabel);
    if (!mounted) return;
    context.push('/ai-programme/loading');
    String? injuriesForRequest = _injuries.trim().isEmpty ? null : _injuries.trim();
    if (injuriesForRequest != null) {
      final sideParts = <String>[];
      for (final part in _bilateralParts) {
        final side = _injurySides[part];
        if (side != null && injuriesForRequest.toLowerCase().contains(part)) {
          sideParts.add('$part: $side side');
        }
      }
      if (sideParts.isNotEmpty) {
        injuriesForRequest = '$injuriesForRequest (${sideParts.join(', ')})';
      }
    }
    final userScorecard = await ref.read(userScorecardProvider.future);
    if (!mounted) return;
    final request = ProgrammeGenerationRequest(
      daysPerWeek: _daysPerWeek,
      sessionLengthMinutes: _sessionLengthMinutes,
      goal: _goal,
      blockedDays: _blockedDays.toList(),
      equipment: _equipment,
      age: _age,
      injuriesOrLimitations: injuriesForRequest,
      additionalContext: _additionalContext.trim().isEmpty ? null : _additionalContext.trim(),
      userScorecard: userScorecard,
      previousProgrammeSummary: widget.previousProgrammeSummary,
      exerciseLibrary: exercises,
      startDate: _programStartDate,
      experienceLevel: _experienceLevel,
    );
    ref.read(programmeGenerationProvider.notifier).generate(request);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(userProfileProvider).whenData(_applyProfileOnce);

    final typography = context.themeExt<AppTypography>();
    final spacing = context.themeExt<AppSpacing>();
    final colors = context.themeExt<AppColors>();

    final isIntro = _currentStep == _StepId.intro;
    final progressValue = isIntro ? 0.0 : (_stepIndex / _progressSteps).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        leading: isIntro
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (_stepIndex > 0) {
                    _back();
                  } else if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                },
              ),
        title: isIntro ? null : const Text(''),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isIntro)
              Container(
                height: 4,
                margin: EdgeInsets.zero,
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(progressValue),
                  tween: Tween(begin: 0, end: progressValue),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    backgroundColor: colors.outline.withValues(alpha: 0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(spacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildStepContent(typography, spacing, colors),
                      ),
                    ),
                    SizedBox(height: spacing.md),
                    _buildActions(spacing),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(AppTypography typography, AppSpacing spacing, AppColors colors) {
    switch (_currentStep) {
      case _StepId.intro:
        return _buildIntro(typography, spacing, colors);
      case _StepId.goal:
        return _buildGoal(typography, spacing, colors);
      case _StepId.days:
        return _buildDays(typography, spacing, colors);
      case _StepId.blockedDays:
        return _buildBlockedDays(typography, spacing, colors);
      case _StepId.sessionLength:
        return _buildSessionLength(typography, spacing, colors);
      case _StepId.equipment:
        return _buildEquipment(typography, spacing, colors);
      case _StepId.experience:
        return _buildExperience(typography, spacing, colors);
      case _StepId.age:
        return _buildAge(typography, spacing, colors);
      case _StepId.injuries:
        return _buildInjuries(typography, spacing, colors);
      case _StepId.additional:
        return _buildAdditional(typography, spacing, colors);
      case _StepId.startDate:
        return _buildStartDate(typography, spacing, colors);
      case _StepId.done:
        return _buildDone(typography, spacing, colors);
    }
  }

  Widget _buildIntro(AppTypography typography, AppSpacing spacing, AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppText(AiProgrammeStrings.introHeadline, style: AppTextStyle.display),
        SizedBox(height: spacing.xl),
        AppText(AiProgrammeStrings.introBody, style: AppTextStyle.body, color: colors.outline),
        SizedBox(height: spacing.md),
        AppText(AiProgrammeStrings.introSubline, style: AppTextStyle.caption, color: colors.outline),
      ],
    );
  }

  Widget _choiceCard({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colors = context.themeExt<AppColors>();
    final spacing = context.themeExt<AppSpacing>();
    final radii = context.themeExt<AppRadii>();
    return Material(
      color: selected ? colors.primary.withValues(alpha: 0.09) : colors.surface,
      borderRadius: BorderRadius.circular(radii.md),
      child: InkWell(
        onTap: () {
          ref.read(hapticsServiceProvider).light();
          onTap();
        },
        borderRadius: BorderRadius.circular(radii.md),
        child: AnimatedScale(
          scale: 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          child: Container(
            constraints: BoxConstraints(minHeight: 48),
            padding: EdgeInsets.symmetric(horizontal: spacing.lg, vertical: spacing.md),
            child: Row(
              children: [
                Expanded(child: AppText(label, style: AppTextStyle.body)),
                if (selected) Icon(Icons.check_circle, color: colors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoal(AppTypography typography, AppSpacing spacing, AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText(AiProgrammeStrings.goalHeadline, style: AppTextStyle.title),
        SizedBox(height: spacing.sm),
        AppText(AiProgrammeStrings.goalCaption, style: AppTextStyle.caption, color: colors.outline),
        SizedBox(height: spacing.lg),
        _choiceCard(
          label: AiProgrammeStrings.goalGetStronger,
          selected: _goal == 'get_stronger',
          onTap: () => setState(() => _goal = 'get_stronger'),
        ),
        SizedBox(height: spacing.sm),
        _choiceCard(
          label: AiProgrammeStrings.goalBuildMuscle,
          selected: _goal == 'build_muscle',
          onTap: () => setState(() => _goal = 'build_muscle'),
        ),
        SizedBox(height: spacing.sm),
        _choiceCard(
          label: AiProgrammeStrings.goalLoseWeight,
          selected: _goal == 'lose_fat',
          onTap: () => setState(() => _goal = 'lose_fat'),
        ),
        SizedBox(height: spacing.sm),
        _choiceCard(
          label: AiProgrammeStrings.goalGeneralFitness,
          selected: _goal == 'general_fitness',
          onTap: () => setState(() => _goal = 'general_fitness'),
        ),
      ],
    );
  }

  Widget _buildDays(AppTypography typography, AppSpacing spacing, AppColors colors) {
    const options = [2, 3, 4, 5];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText(AiProgrammeStrings.daysHeadline, style: AppTextStyle.title),
        SizedBox(height: spacing.sm),
        AppText(AiProgrammeStrings.daysCaption, style: AppTextStyle.caption, color: colors.outline),
        SizedBox(height: spacing.lg),
        ...options.map((d) => Padding(
              padding: EdgeInsets.only(bottom: spacing.sm),
              child: _choiceCard(
                label: '$d days',
                selected: _daysPerWeek == d,
                onTap: () => setState(() => _daysPerWeek = d),
              ),
            )),
      ],
    );
  }

  static const List<String> _weekdays = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
  ];

  /// Suggested training days by count (Mon=1, Sun=7). User can tap to swap.
  static List<String> _suggestedDaysFor(int daysPerWeek) {
    const patterns = {
      2: ['monday', 'thursday'],
      3: ['monday', 'wednesday', 'friday'],
      4: ['monday', 'tuesday', 'thursday', 'saturday'],
      5: ['monday', 'tuesday', 'wednesday', 'friday', 'saturday'],
    };
    return List<String>.from(patterns[daysPerWeek] ?? patterns[3]!);
  }

  Widget _buildBlockedDays(AppTypography typography, AppSpacing spacing, AppColors colors) {
    final radii = context.themeExt<AppRadii>();
    final selectedDays = _weekdays.where((d) => !_blockedDays.contains(d)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText(AiProgrammeStrings.reflectionDays(_daysPerWeek), style: AppTextStyle.caption, color: colors.outline),
        SizedBox(height: spacing.sm),
        AppText(AiProgrammeStrings.blockedDaysHeadline, style: AppTextStyle.title),
        SizedBox(height: spacing.sm),
        AppText(AiProgrammeStrings.blockedDaysCaption, style: AppTextStyle.caption, color: colors.outline),
        SizedBox(height: spacing.lg),
        AppText(AiProgrammeStrings.blockedDaysSuggest, style: AppTextStyle.label, color: colors.outline),
        SizedBox(height: spacing.sm),
        Wrap(
          spacing: spacing.sm,
          runSpacing: spacing.sm,
          children: _weekdays.map((d) {
            final isSelected = selectedDays.contains(d);
            final label = d[0].toUpperCase() + d.substring(1).toLowerCase();
            return Material(
              color: isSelected ? colors.primary.withValues(alpha: 0.12) : colors.surface,
              borderRadius: BorderRadius.circular(radii.md),
              child: InkWell(
                onTap: () => setState(() {
                  if (isSelected) {
                    if (selectedDays.length <= 1) return;
                    _blockedDays.add(d);
                    if (_blockedDays.length > 7 - _daysPerWeek) {
                      final toUnblock = _weekdays.firstWhere(
                        (x) => _blockedDays.contains(x) && x != d,
                      );
                      _blockedDays.remove(toUnblock);
                    }
                  } else {
                    _blockedDays.remove(d);
                    final nowSelected = _weekdays.where((x) => !_blockedDays.contains(x)).toList();
                    if (nowSelected.length > _daysPerWeek) {
                      _blockedDays.add(nowSelected.first);
                    }
                  }
                }),
                borderRadius: BorderRadius.circular(radii.md),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: spacing.md, vertical: spacing.sm),
                  child: Text(label, style: TextStyle(
                    color: isSelected ? colors.primary : colors.outline,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  )),
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: spacing.sm),
        AppText(AiProgrammeStrings.blockedDaysTapHint, style: AppTextStyle.caption, color: colors.outline),
      ],
    );
  }

  Widget _buildSessionLength(AppTypography typography, AppSpacing spacing, AppColors colors) {
    const options = [30, 45, 60, 90];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText(AiProgrammeStrings.sessionLengthHeadline, style: AppTextStyle.title),
        SizedBox(height: spacing.sm),
        AppText(AiProgrammeStrings.sessionLengthCaption, style: AppTextStyle.caption, color: colors.outline),
        SizedBox(height: spacing.lg),
        ...options.map((m) => Padding(
              padding: EdgeInsets.only(bottom: spacing.sm),
              child: _choiceCard(
                label: '$m${AiProgrammeStrings.sessionLengthSuffix}',
                selected: _sessionLengthMinutes == m,
                onTap: () => setState(() => _sessionLengthMinutes = m),
              ),
            )),
      ],
    );
  }

  Widget _buildEquipment(AppTypography typography, AppSpacing spacing, AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText(AiProgrammeStrings.reflectionEquipment(_daysPerWeek, _sessionLengthMinutes), style: AppTextStyle.caption, color: colors.outline),
        SizedBox(height: spacing.sm),
        AppText(AiProgrammeStrings.equipmentHeadline, style: AppTextStyle.title),
        SizedBox(height: spacing.sm),
        AppText(AiProgrammeStrings.equipmentCaption, style: AppTextStyle.caption, color: colors.outline),
        SizedBox(height: spacing.lg),
        _choiceCard(
          label: AiProgrammeStrings.equipmentFullGym,
          selected: _equipment == 'full_gym',
          onTap: () => setState(() => _equipment = 'full_gym'),
        ),
        SizedBox(height: spacing.sm),
        _choiceCard(
          label: AiProgrammeStrings.equipmentHome,
          selected: _equipment == 'home',
          onTap: () => setState(() => _equipment = 'home'),
        ),
        SizedBox(height: spacing.sm),
        _choiceCard(
          label: AiProgrammeStrings.equipmentBodyweight,
          selected: _equipment == 'bodyweight',
          onTap: () => setState(() => _equipment = 'bodyweight'),
        ),
      ],
    );
  }

  Widget _buildExperience(AppTypography typography, AppSpacing spacing, AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText(AiProgrammeStrings.experienceHeadline, style: AppTextStyle.title),
        SizedBox(height: spacing.sm),
        AppText(AiProgrammeStrings.experienceCaption, style: AppTextStyle.caption, color: colors.outline),
        SizedBox(height: spacing.lg),
        _choiceCard(
          label: AiProgrammeStrings.experienceNew,
          selected: _experienceLevel == 'never',
          onTap: () => setState(() => _experienceLevel = 'never'),
        ),
        SizedBox(height: spacing.sm),
        _choiceCard(
          label: AiProgrammeStrings.experienceSome,
          selected: _experienceLevel == 'some',
          onTap: () => setState(() => _experienceLevel = 'some'),
        ),
        SizedBox(height: spacing.sm),
        _choiceCard(
          label: AiProgrammeStrings.experienceRegular,
          selected: _experienceLevel == 'regular',
          onTap: () => setState(() => _experienceLevel = 'regular'),
        ),
        SizedBox(height: spacing.sm),
        AppText(AiProgrammeStrings.experienceSkipHint, style: AppTextStyle.caption, color: colors.outline),
      ],
    );
  }

  Widget _buildAge(AppTypography typography, AppSpacing spacing, AppColors colors) {
    final radii = context.themeExt<AppRadii>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText(AiProgrammeStrings.ageHeadline, style: AppTextStyle.title),
        SizedBox(height: spacing.sm),
        AppText(AiProgrammeStrings.ageCaption, style: AppTextStyle.caption, color: colors.outline),
        SizedBox(height: spacing.lg),
        SizedBox(
          height: 56,
          child: ListWheelScrollView.useDelegate(
            controller: _ageScrollController,
            itemExtent: 56,
            physics: const FixedExtentScrollPhysics(),
            diameterRatio: 100,
            onSelectedItemChanged: (index) {
              ref.read(hapticsServiceProvider).light();
              setState(() => _age = _kMinAge + index);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: _kMaxAge - _kMinAge + 1,
              builder: (context, index) {
                final age = _kMinAge + index;
                return Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(radii.sm),
                  ),
                  child: AppText(
                    '$age',
                    style: AppTextStyle.title,
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInjuries(AppTypography typography, AppSpacing spacing, AppColors colors) {
    final radii = context.themeExt<AppRadii>();
    final partsNeedingSide = _bilateralParts
        .where((p) => _partNeedsSideFollowUp(_injuries, p))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText(AiProgrammeStrings.injuriesHeadline, style: AppTextStyle.title),
        SizedBox(height: spacing.sm),
        AppText(AiProgrammeStrings.injuriesCaption, style: AppTextStyle.caption, color: colors.outline),
        SizedBox(height: spacing.lg),
        TextField(
          controller: _injuriesController,
          keyboardType: TextInputType.multiline,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: AiProgrammeStrings.injuriesHint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onChanged: (v) => setState(() => _injuries = v),
        ),
        for (final part in partsNeedingSide) ...[
          SizedBox(height: spacing.md),
          AppText(
            'Which ${part[0].toUpperCase()}${part.substring(1)}?',
            style: AppTextStyle.label,
            color: colors.outline,
          ),
          SizedBox(height: spacing.sm),
          Wrap(
            spacing: spacing.sm,
            runSpacing: spacing.sm,
            children: [
              _injurySideChip(colors, radii, spacing, part, 'left', AiProgrammeStrings.injurySideLeft),
              _injurySideChip(colors, radii, spacing, part, 'right', AiProgrammeStrings.injurySideRight),
              _injurySideChip(colors, radii, spacing, part, 'both', AiProgrammeStrings.injurySideBoth),
            ],
          ),
        ],
      ],
    );
  }

  Widget _injurySideChip(AppColors colors, AppRadii radii, AppSpacing spacing, String partKey, String value, String label) {
    final selected = _injurySides[partKey] == value;
    return Material(
      color: selected ? colors.primary.withValues(alpha: 0.12) : colors.surface,
      borderRadius: BorderRadius.circular(radii.md),
      child: InkWell(
        onTap: () => setState(() {
          _injurySides[partKey] = _injurySides[partKey] == value ? null : value;
        }),
        borderRadius: BorderRadius.circular(radii.md),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing.md, vertical: spacing.sm),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? colors.primary : colors.outline,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdditional(AppTypography typography, AppSpacing spacing, AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText(AiProgrammeStrings.preferencesHeadline, style: AppTextStyle.title),
        SizedBox(height: spacing.sm),
        AppText(AiProgrammeStrings.preferencesPersonaliseLine, style: AppTextStyle.body, color: colors.outline),
        SizedBox(height: spacing.xs),
        AppText(AiProgrammeStrings.preferencesCaption, style: AppTextStyle.caption, color: colors.outline),
        SizedBox(height: spacing.lg),
        TextField(
          controller: _additionalController,
          keyboardType: TextInputType.multiline,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: AiProgrammeStrings.preferencesPlaceholder,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onChanged: (v) => setState(() => _additionalContext = v),
        ),
      ],
    );
  }

  Widget _buildStartDate(AppTypography typography, AppSpacing spacing, AppColors colors) {
    final formatted = DateFormat('EEEE, d MMM yyyy').format(_programStartDate);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText(AiProgrammeStrings.startDateTitle, style: AppTextStyle.title),
        SizedBox(height: spacing.sm),
        AppText(AiProgrammeStrings.startDateHint, style: AppTextStyle.caption, color: colors.outline),
        SizedBox(height: spacing.lg),
        AppCard(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _programStartDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              helpText: AiProgrammeStrings.startDatePickerHelp,
            );
            if (picked != null) {
              setState(() => _programStartDate = DateTime(picked.year, picked.month, picked.day));
            }
          },
          child: Row(
            children: [
              Icon(Icons.calendar_today, color: colors.primary, size: 20),
              SizedBox(width: spacing.md),
              Expanded(child: AppText(formatted, style: AppTextStyle.body)),
              Icon(Icons.chevron_right, color: colors.outline),
            ],
          ),
        ),
      ],
    );
  }

  String get _goalLabel {
    switch (_goal) {
      case 'get_stronger': return AiProgrammeStrings.goalGetStronger;
      case 'build_muscle': return AiProgrammeStrings.goalBuildMuscle;
      case 'lose_fat': return AiProgrammeStrings.goalLoseWeight;
      default: return AiProgrammeStrings.goalGeneralFitness;
    }
  }

  String get _equipmentLabel {
    switch (_equipment) {
      case 'full_gym': return AiProgrammeStrings.equipmentFullGym;
      case 'home': return AiProgrammeStrings.equipmentHome;
      case 'bodyweight': return AiProgrammeStrings.equipmentBodyweight;
      default: return AiProgrammeStrings.equipmentFullGym;
    }
  }

  String get _experienceLabel {
    switch (_experienceLevel) {
      case 'never': return AiProgrammeStrings.experienceNew;
      case 'some': return AiProgrammeStrings.experienceSome;
      case 'regular': return AiProgrammeStrings.experienceRegular;
      default: return '';
    }
  }

  Widget _buildDone(AppTypography typography, AppSpacing spacing, AppColors colors) {
    final startFormatted = DateFormat('EEEE, d MMM').format(_programStartDate);
    final hasInjuries = _injuries.trim().isNotEmpty;
    final hasPreferences = _additionalContext.trim().isNotEmpty;
    final injuriesLine = hasInjuries
        ? (_injuries.length > 60 ? '${_injuries.trim().substring(0, 60)}...' : _injuries.trim())
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText(AiProgrammeStrings.readyHeadline, style: AppTextStyle.title),
        SizedBox(height: spacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _summaryRow('🎯', _goalLabel),
              SizedBox(height: spacing.xs),
              _summaryRow('📅', '$_daysPerWeek days a week · $_sessionLengthMinutes min sessions'),
              SizedBox(height: spacing.xs),
              _summaryRow('🏋️', _equipmentLabel),
              if (_experienceLevel != null) ...[
                SizedBox(height: spacing.xs),
                _summaryRow('📊', _experienceLabel),
              ],
              SizedBox(height: spacing.xs),
              _summaryRow('📍', 'Starting $startFormatted'),
              if (injuriesLine != null) ...[
                SizedBox(height: spacing.xs),
                _summaryRow('⚠️', 'Working around: $injuriesLine'),
              ],
              if (hasPreferences) ...[
                SizedBox(height: spacing.xs),
                _summaryRow('👊', AiProgrammeStrings.revealPreferencesNoted),
              ],
            ],
          ),
        ),
        SizedBox(height: spacing.md),
        AppText(AiProgrammeStrings.readyCaption, style: AppTextStyle.caption, color: colors.outline),
        SizedBox(height: spacing.xs),
        AppText(AiProgrammeStrings.readyCaptionRationale, style: AppTextStyle.caption, color: colors.outline),
      ],
    );
  }

  Widget _summaryRow(String emoji, String text) {
    final typography = context.themeExt<AppTypography>();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: typography.label),
        SizedBox(width: 8),
        Expanded(child: AppText(text, style: AppTextStyle.body)),
      ],
    );
  }

  Widget _buildActions(AppSpacing spacing) {
    if (_currentStep == _StepId.intro) {
      return AppButton(
        label: AiProgrammeStrings.introCta,
        onPressed: _next,
        isFullWidth: true,
      );
    }
    if (_currentStep == _StepId.done) {
      return AppButton(
        label: AiProgrammeStrings.buildMyProgrammeCta,
        onPressed: _generate,
        isFullWidth: true,
      );
    }
    return Row(
      children: [
        if (_stepIndex > 0)
          TextButton(
            onPressed: _back,
            child: Text(AiProgrammeStrings.back),
          ),
        const Spacer(),
        FilledButton(
          onPressed: _next,
          child: Text(AiProgrammeStrings.next),
        ),
      ],
    );
  }
}
