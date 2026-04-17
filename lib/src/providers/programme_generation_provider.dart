import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/data/programme_generation_service.dart'
    show
        ProgrammeGenerationLimitException,
        ProgrammeGenerationRequest,
        ProgrammeGenerationResult,
        ProgrammeGenerationService;
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/premium_provider.dart';
import 'package:fytter/src/presentation/workout/workout_templates_screen.dart'
    show workoutTemplatesFutureProvider;

final programmeGenerationServiceProvider = Provider<ProgrammeGenerationService>((ref) {
  final programRepo = ref.watch(programRepositoryProvider);
  final workoutRepo = ref.watch(workoutRepositoryProvider);
  return ProgrammeGenerationService(
    programRepository: programRepo,
    workoutRepository: workoutRepo,
  );
});

/// State for the programme generation flow: idle, loading, success, or error.
sealed class ProgrammeGenerationState {}

class ProgrammeGenerationIdle extends ProgrammeGenerationState {}

class ProgrammeGenerationLoading extends ProgrammeGenerationState {}

class ProgrammeGenerationSuccess extends ProgrammeGenerationState {
  final ProgrammeGenerationResult result;

  ProgrammeGenerationSuccess(this.result);
}

class ProgrammeGenerationError extends ProgrammeGenerationState {
  final String message;

  ProgrammeGenerationError(this.message);
}

class ProgrammeGenerationLimitReached extends ProgrammeGenerationState {}

/// Notifier that runs generation and exposes loading/success/error state.
class ProgrammeGenerationNotifier extends StateNotifier<ProgrammeGenerationState> {
  ProgrammeGenerationNotifier(this._ref) : super(ProgrammeGenerationIdle());

  final Ref _ref;

  Future<void> generate(ProgrammeGenerationRequest request) async {
    state = ProgrammeGenerationLoading();
    try {
      final service = _ref.read(programmeGenerationServiceProvider);
      final result = await service.generateAndSave(request);
      state = ProgrammeGenerationSuccess(result);
      _ref.invalidate(programsFutureProvider);
      _ref.invalidate(workoutTemplatesFutureProvider);
    } catch (e) {
      if (e is ProgrammeGenerationLimitException) {
        state = ProgrammeGenerationLimitReached();
      } else {
        state = ProgrammeGenerationError(e.toString());
      }
    }
  }

  void reset() {
    state = ProgrammeGenerationIdle();
  }
}

final programmeGenerationProvider =
    StateNotifierProvider<ProgrammeGenerationNotifier, ProgrammeGenerationState>((ref) {
  return ProgrammeGenerationNotifier(ref);
});

/// Summary of the programme being generated (for loading screen first message). Set before navigate to loading; cleared when leaving loading.
final pendingProgrammeSummaryProvider = StateProvider<({int days, String goalLabel})?>((ref) => null);

/// Whether the user can access AI programme generation.
/// Derived from [premiumStatusProvider]; while loading, treated as non-premium (safe default).
/// Override in tests with [aiProgrammePremiumProvider.overrideWith].
final aiProgrammePremiumProvider = Provider<bool>((ref) {
  final async = ref.watch(premiumStatusProvider);
  return async.maybeWhen(data: (premium) => premium, orElse: () => false);
});

/// Pre-workout amber/red adaptation (rule engine + future `adjustWorkout`) — same entitlement as AI programme.
final workoutAdaptationPremiumProvider = Provider<bool>(
  (ref) => ref.watch(aiProgrammePremiumProvider),
);
