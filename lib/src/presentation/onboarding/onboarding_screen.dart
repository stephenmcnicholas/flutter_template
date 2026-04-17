import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/user_profile_repository.dart';
import '../../domain/user_profile.dart';
import '../../providers/unit_settings_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../utils/format_utils.dart';
import '../shared/app_button.dart';
import '../shared/app_card.dart';
import '../shared/app_text.dart';
import '../theme.dart';
import 'onboarding_strings.dart';

/// First-launch onboarding: collect profile (goal, days, length, equipment, etc.).
/// Plan: docs/plans/2026-02-26-onboarding-implementation-plan.md
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

enum _StepId {
  welcome,
  goal,
  days,
  sessionLength,
  equipment,
  experience,
  weightHeight,
  injuries,
  done,
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _stepIndex = 0;
  PrimaryGoal? _primaryGoal;
  int? _daysPerWeek;
  int? _sessionLengthMinutes;
  EquipmentAccess? _equipment;
  ExperienceLevel? _experienceLevel;
  double? _weightKg;
  double? _heightCm;
  String? _injuriesNotes;
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _injuriesController = TextEditingController();

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _injuriesController.dispose();
    super.dispose();
  }

  List<_StepId> get _stepIds {
    final base = [
      _StepId.welcome,
      _StepId.goal,
      _StepId.days,
      _StepId.sessionLength,
      _StepId.equipment,
      _StepId.experience,
    ];
    final showWeight = _primaryGoal == PrimaryGoal.loseFat ||
        _primaryGoal == PrimaryGoal.generalFitness;
    return [
      ...base,
      if (showWeight) _StepId.weightHeight,
      _StepId.injuries,
      _StepId.done,
    ];
  }

  _StepId get _currentStep => _stepIds[_stepIndex];
  int get _totalSteps => _stepIds.length;

  void _next() {
    if (_stepIndex >= _stepIds.length - 1) return;
    setState(() => _stepIndex++);
  }

  void _back() {
    if (_stepIndex <= 0) return;
    setState(() => _stepIndex--);
  }

  Future<void> _complete() async {
    final goal = _primaryGoal ?? PrimaryGoal.generalFitness;
    final days = _daysPerWeek ?? kDefaultDaysPerWeek;
    final length = _sessionLengthMinutes ?? kDefaultSessionLengthMinutes;
    final equipment = _equipment ?? EquipmentAccess.fullGym;
    final experience = _experienceLevel ?? ExperienceLevel.never;
    final profile = UserProfile(
      id: kLocalProfileId,
      primaryGoal: goal,
      daysPerWeek: days,
      sessionLengthMinutes: length,
      equipment: equipment,
      experienceLevel: experience,
      injuriesNotes: _injuriesNotes?.trim().isEmpty == true ? null : _injuriesNotes?.trim(),
      weightKg: _weightKg,
      heightCm: _heightCm,
      onboardingCompletedAt: DateTime.now(),
    );
    final repo = ref.read(userProfileRepositoryProvider);
    await repo.saveProfile(profile);
    if (!mounted) return;
    ref.invalidate(userProfileProvider);
    ref.invalidate(hasCompletedOnboardingProvider);
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final typography = context.themeExt<AppTypography>();
    final spacing = context.themeExt<AppSpacing>();
    final colors = context.themeExt<AppColors>();

    return Scaffold(
      appBar: _stepIndex > 0 && _currentStep != _StepId.welcome
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _back,
              ),
              title: Text(
                'Step ${_stepIndex + 1} of $_totalSteps',
                style: typography.label,
              ),
            )
          : null,
      body: SafeArea(
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
    );
  }

  Widget _buildStepContent(
    AppTypography typography,
    AppSpacing spacing,
    AppColors colors,
  ) {
    switch (_currentStep) {
      case _StepId.welcome:
        return _buildWelcome(typography, spacing);
      case _StepId.goal:
        return _buildGoal(typography, spacing, colors);
      case _StepId.days:
        return _buildDays(typography, spacing, colors);
      case _StepId.sessionLength:
        return _buildSessionLength(typography, spacing, colors);
      case _StepId.equipment:
        return _buildEquipment(typography, spacing, colors);
      case _StepId.experience:
        return _buildExperience(typography, spacing, colors);
      case _StepId.weightHeight:
        return _buildWeightHeight(typography, spacing);
      case _StepId.injuries:
        return _buildInjuries(typography, spacing);
      case _StepId.done:
        return _buildDone(typography, spacing);
    }
  }

  Widget _buildWelcome(AppTypography typography, AppSpacing spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(OnboardingStrings.welcomeTitle, style: typography.headline),
        SizedBox(height: spacing.md),
        Text(OnboardingStrings.welcomeBody, style: typography.body),
      ],
    );
  }

  Widget _buildGoal(
    AppTypography typography,
    AppSpacing spacing,
    AppColors colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(OnboardingStrings.goalTitle, style: typography.title),
        SizedBox(height: spacing.lg),
        _choiceCard(
          label: OnboardingStrings.goalGetStronger,
          selected: _primaryGoal == PrimaryGoal.getStronger,
          onTap: () => setState(() => _primaryGoal = PrimaryGoal.getStronger),
        ),
        SizedBox(height: spacing.sm),
        _choiceCard(
          label: OnboardingStrings.goalBuildMuscle,
          selected: _primaryGoal == PrimaryGoal.buildMuscle,
          onTap: () => setState(() => _primaryGoal = PrimaryGoal.buildMuscle),
        ),
        SizedBox(height: spacing.sm),
        _choiceCard(
          label: OnboardingStrings.goalLoseFat,
          selected: _primaryGoal == PrimaryGoal.loseFat,
          onTap: () => setState(() => _primaryGoal = PrimaryGoal.loseFat),
        ),
        SizedBox(height: spacing.sm),
        _choiceCard(
          label: OnboardingStrings.goalGeneralFitness,
          selected: _primaryGoal == PrimaryGoal.generalFitness,
          onTap: () => setState(() => _primaryGoal = PrimaryGoal.generalFitness),
        ),
      ],
    );
  }

  Widget _choiceCard({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colors = context.themeExt<AppColors>();
    return AppCard(
      onTap: onTap,
      compact: true,
      child: Row(
        children: [
          Expanded(child: AppText(label, style: AppTextStyle.body)),
          if (selected) Icon(Icons.check_circle, color: colors.primary),
        ],
      ),
    );
  }

  Widget _buildDays(
    AppTypography typography,
    AppSpacing spacing,
    AppColors colors,
  ) {
    const options = [2, 3, 4, 5];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(OnboardingStrings.daysTitle, style: typography.title),
        SizedBox(height: spacing.lg),
        ...options.map((d) {
          return Padding(
            padding: EdgeInsets.only(bottom: spacing.sm),
            child: _choiceCard(
              label: '$d days',
              selected: _daysPerWeek == d,
              onTap: () => setState(() => _daysPerWeek = d),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSessionLength(
    AppTypography typography,
    AppSpacing spacing,
    AppColors colors,
  ) {
    const options = [30, 45, 60, 90];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(OnboardingStrings.sessionLengthTitle, style: typography.title),
        SizedBox(height: spacing.lg),
        ...options.map((m) {
          return Padding(
            padding: EdgeInsets.only(bottom: spacing.sm),
            child: _choiceCard(
              label: '$m min',
              selected: _sessionLengthMinutes == m,
              onTap: () => setState(() => _sessionLengthMinutes = m),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEquipment(
    AppTypography typography,
    AppSpacing spacing,
    AppColors colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(OnboardingStrings.equipmentTitle, style: typography.title),
        SizedBox(height: spacing.lg),
        _choiceCard(
          label: OnboardingStrings.equipmentHomeDumbbells,
          selected: _equipment == EquipmentAccess.homeDumbbells,
          onTap: () => setState(() => _equipment = EquipmentAccess.homeDumbbells),
        ),
        SizedBox(height: spacing.sm),
        _choiceCard(
          label: OnboardingStrings.equipmentFullGym,
          selected: _equipment == EquipmentAccess.fullGym,
          onTap: () => setState(() => _equipment = EquipmentAccess.fullGym),
        ),
        SizedBox(height: spacing.sm),
        _choiceCard(
          label: OnboardingStrings.equipmentBodyweightOnly,
          selected: _equipment == EquipmentAccess.bodyweightOnly,
          onTap: () =>
              setState(() => _equipment = EquipmentAccess.bodyweightOnly),
        ),
      ],
    );
  }

  Widget _buildExperience(
    AppTypography typography,
    AppSpacing spacing,
    AppColors colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(OnboardingStrings.experienceTitle, style: typography.title),
        SizedBox(height: spacing.lg),
        _choiceCard(
          label: OnboardingStrings.experienceNever,
          selected: _experienceLevel == ExperienceLevel.never,
          onTap: () =>
              setState(() => _experienceLevel = ExperienceLevel.never),
        ),
        SizedBox(height: spacing.sm),
        _choiceCard(
          label: OnboardingStrings.experienceSome,
          selected: _experienceLevel == ExperienceLevel.some,
          onTap: () => setState(() => _experienceLevel = ExperienceLevel.some),
        ),
        SizedBox(height: spacing.sm),
        _choiceCard(
          label: OnboardingStrings.experienceRegular,
          selected: _experienceLevel == ExperienceLevel.regular,
          onTap: () =>
              setState(() => _experienceLevel = ExperienceLevel.regular),
        ),
      ],
    );
  }

  Widget _buildWeightHeight(AppTypography typography, AppSpacing spacing) {
    final unitSettings = ref.watch(unitSettingsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(OnboardingStrings.weightHeightTitle, style: typography.title),
        SizedBox(height: spacing.lg),
        TextField(
          controller: _weightController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: OnboardingStrings.weightLabel,
            hintText: unitSettings.weightUnit == WeightUnit.kg ? 'kg' : 'lb',
            border: const OutlineInputBorder(),
          ),
          onChanged: (v) {
            final n = double.tryParse(v);
            if (n != null && n > 0) {
              _weightKg = unitSettings.weightUnit == WeightUnit.kg
                  ? n
                  : n / 2.20462;
            } else {
              _weightKg = null;
            }
          },
        ),
        SizedBox(height: spacing.md),
        TextField(
          controller: _heightController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: OnboardingStrings.heightLabel,
            hintText: 'cm',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) {
            final n = double.tryParse(v);
            _heightCm = (n != null && n > 0) ? n : null;
          },
        ),
      ],
    );
  }

  Widget _buildInjuries(AppTypography typography, AppSpacing spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(OnboardingStrings.injuriesTitle, style: typography.title),
        SizedBox(height: spacing.lg),
        TextField(
          controller: _injuriesController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: OnboardingStrings.injuriesHint,
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => setState(() => _injuriesNotes = v),
        ),
      ],
    );
  }

  Widget _buildDone(AppTypography typography, AppSpacing spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(OnboardingStrings.doneTitle, style: typography.headline),
        SizedBox(height: spacing.md),
        Text(OnboardingStrings.doneBody, style: typography.body),
      ],
    );
  }

  Widget _buildActions(AppSpacing spacing) {
    switch (_currentStep) {
      case _StepId.welcome:
        return AppButton(
          label: OnboardingStrings.getStarted,
          onPressed: _next,
          isFullWidth: true,
        );
      case _StepId.done:
        return AppButton(
          label: OnboardingStrings.goToFytter,
          onPressed: _complete,
          isFullWidth: true,
        );
      default:
        return Row(
          children: [
            Expanded(
              child: AppButton(
                label: OnboardingStrings.skip,
                variant: AppButtonVariant.secondary,
                onPressed: () {
                  _applySkipDefault();
                  _next();
                },
                isFullWidth: true,
              ),
            ),
            SizedBox(width: spacing.md),
            Expanded(
              child: AppButton(
                label: OnboardingStrings.next,
                onPressed: _next,
                isFullWidth: true,
              ),
            ),
          ],
        );
    }
  }

  void _applySkipDefault() {
    setState(() {
      switch (_currentStep) {
        case _StepId.goal:
          _primaryGoal ??= PrimaryGoal.generalFitness;
          break;
        case _StepId.days:
          _daysPerWeek ??= kDefaultDaysPerWeek;
          break;
        case _StepId.sessionLength:
          _sessionLengthMinutes ??= kDefaultSessionLengthMinutes;
          break;
        case _StepId.equipment:
          _equipment ??= EquipmentAccess.fullGym;
          break;
        case _StepId.experience:
          _experienceLevel ??= ExperienceLevel.never;
          break;
        case _StepId.weightHeight:
        case _StepId.injuries:
          break;
        default:
          break;
      }
    });
  }
}
