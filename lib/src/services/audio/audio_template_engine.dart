import 'dart:math';

import 'package:fytter/src/domain/exercise_instructions.dart';
import 'package:fytter/src/services/audio/audio_sentence_specs.dart';
import 'package:fytter/src/services/audio/audio_service.dart';
import 'package:fytter/src/services/audio/coaching_audio_tier.dart';
import 'package:fytter/src/services/audio/sentence_library.dart';

/// Builds clip specs for each audio template. Handles Template 4 final-set
/// edge case: when there is no next set, use "last set of this exercise"
/// instead of weight direction.
class AudioTemplateEngine {
  AudioTemplateEngine({Random? random}) : _random = random ?? Random();

  final Random _random;

  // ——— Modular clip categories (Type A) ———
  static const String _workoutBookends = 'workout_bookends';
  static const String _exerciseCount = 'exercise_count';
  static const String _workoutDuration = 'workout_duration';
  static const String _setSequencing = 'set_sequencing';
  static const String _weightDirection = 'weight_direction';
  static const String _exerciseTransitions = 'exercise_transitions';
  static const String _encouragement = 'encouragement';
  static const String _connective = 'connective';
  static const String _exerciseNames = 'exercise_names';

  /// Template 1 — Workout intro: dynamic workout intro (if workoutId provided), X exercises, about X minutes, opening.
  /// Slot 1 is skipped gracefully at playback if the workout intro file is missing.
  List<AudioClipSpec> template1WorkoutIntro({
    String? workoutId,
    required int exerciseCount,
    required int durationMinutes,
  }) {
    final list = <AudioClipSpec>[];
    if (workoutId != null && workoutId.isNotEmpty) {
      list.add(AudioClipSpec.workoutIntro(workoutId: workoutId));
    }
    list.addAll([
      AudioClipSpec.modular(
        category: _exerciseCount,
        modularId: _exerciseCountToClipId(exerciseCount),
      ),
      AudioClipSpec.modular(
        category: _workoutDuration,
        modularId: _durationToClipId(durationMinutes),
      ),
      AudioClipSpec.modular(
        category: _workoutBookends,
        modularId: _randomOpeningBookend(),
      ),
    ]);
    return list;
  }

  /// Template 2 — First exercise setup: first exercise today, exercise name,
  /// setup sentences, movement sentences, "ready when you are".
  /// Breathing is intentionally absent here — it plays on 2nd+ sets via Template 5.
  List<AudioClipSpec> template2FirstExerciseSetup({
    required String exerciseId,
    required ExerciseInstructions instructions,
    required CoachingAudioTier tier,
    required SentenceLibrary sentences,
  }) {
    return [
      const AudioClipSpec.modular(category: _exerciseTransitions, modularId: 'transition_first_exercise'),
      AudioClipSpec.modular(category: _exerciseNames, modularId: exerciseId),
      ...audioSpecsForCueField(field: instructions.setup, tier: tier, sentences: sentences),
      ...audioSpecsForCueField(field: instructions.movement, tier: tier, sentences: sentences),
      const AudioClipSpec.modular(category: _connective, modularId: 'connective_when_ready'),
    ];
  }

  /// Template 3a — Exercise transition teaser. Fires immediately when rest starts
  /// and a new exercise is coming up. Short 3-clip cue: encouragement to rest,
  /// preview of next exercise name. Full setup/movement plays at rest end via T5.
  List<AudioClipSpec> template3aExerciseTeaser({
    required String exerciseId,
  }) {
    return [
      const AudioClipSpec.modular(category: _connective, modularId: 'connective_take_rest'),
      const AudioClipSpec.modular(category: _exerciseTransitions, modularId: 'transition_next_up'),
      AudioClipSpec.modular(category: _exerciseNames, modularId: exerciseId),
    ];
  }

  /// Template 4 — Set complete. Returns 2 clips when more sets of the same exercise
  /// remain (encouragement + weight direction); 1 clip when it's the final set of
  /// the exercise (encouragement only). Set-sequencing has moved to Template 5.
  List<AudioClipSpec> template4SameExerciseNextSet({
    required bool isFinalSetOfExercise,
    required double? currentSetWeight,
    required double? nextSetProgrammedWeight,
  }) {
    if (isFinalSetOfExercise) {
      return [_randomEncouragement()];
    }
    return [
      _randomEncouragement(),
      _weightDirectionClip(currentSetWeight, nextSetProgrammedWeight),
    ];
  }

  /// Template 5 — Rest-end notification.
  ///
  /// Dispatch priority:
  /// 1. [isFirstSetOfExercise] = true → T3b: exercise name + setup + movement + when_youre_ready
  ///    (single-set exercises also land here via isFirstSetOfExercise, regardless of isLastSetOfExercise)
  /// 2. [isLastSetOfExercise] = true → its_the_last_set + breathing + lets_go
  /// 3. Sets 2–6 → its_your_Nth_set + breathing + lets_go
  /// 4. Set 7+ → next_set + breathing + lets_go
  ///
  /// Exercise name is only spoken on the first set (case 1). Subsequent sets omit
  /// it — the user is already at the exercise and repeating the name is redundant.
  List<AudioClipSpec> template5RestEnd({
    required String exerciseId,
    required int setIndex1Based,
    required bool isFirstSetOfExercise,
    required bool isLastSetOfExercise,
    required ExerciseInstructions instructions,
    required SentenceLibrary sentences,
    required CoachingAudioTier tier,
  }) {
    // T3b: full intro for first set of a (new) exercise
    if (isFirstSetOfExercise) {
      return [
        AudioClipSpec.modular(category: _exerciseNames, modularId: exerciseId),
        ...audioSpecsForCueField(field: instructions.setup, tier: tier, sentences: sentences),
        ...audioSpecsForCueField(field: instructions.movement, tier: tier, sentences: sentences),
        const AudioClipSpec.modular(category: _connective, modularId: 'connective_when_ready'),
      ];
    }

    // Set label: its_the_last_set or its_your_Nth_set or next_set
    final AudioClipSpec setLabel;
    if (isLastSetOfExercise) {
      setLabel = const AudioClipSpec.modular(category: _setSequencing, modularId: 'its_the_last_set');
    } else {
      setLabel = _setSequencingClipTemplate5Declarative(setIndex1Based);
    }

    return [
      setLabel,
      if (instructions.breathingCue != null)
        ...audioSpecsForCueField(
          field: instructions.breathingCue!,
          tier: tier,
          sentences: sentences,
        ),
      const AudioClipSpec.modular(category: _connective, modularId: 'connective_lets_go'),
    ];
  }

  /// Template 6 — On-demand good form (first tap).
  List<AudioClipSpec> template6OnDemandGoodForm({
    required ExerciseInstructions instructions,
    required CoachingAudioTier tier,
    required SentenceLibrary sentences,
  }) {
    final g = instructions.goodFormFeels;
    if (g == null) return [];
    return audioSpecsForCueField(field: g, tier: tier, sentences: sentences);
  }

  /// Template 7 — On-demand common fix 1 (second tap).
  List<AudioClipSpec> template7OnDemandCommonFix1({
    required ExerciseInstructions instructions,
    required CoachingAudioTier tier,
    required SentenceLibrary sentences,
  }) {
    final fixes = instructions.commonFixes;
    if (fixes.isEmpty) return [];
    return audioSpecsForCommonFix(fix: fixes.first, tier: tier, sentences: sentences);
  }

  /// Template 8 — On-demand common fix 2 or replay fix 1 (third+ tap).
  List<AudioClipSpec> template8OnDemandCommonFix2({
    required ExerciseInstructions instructions,
    required CoachingAudioTier tier,
    required SentenceLibrary sentences,
    required bool hasFix2,
  }) {
    final fixes = instructions.commonFixes;
    if (fixes.isEmpty) return [];
    final fix = hasFix2 && fixes.length >= 2 ? fixes[1] : fixes[0];
    return audioSpecsForCommonFix(fix: fix, tier: tier, sentences: sentences);
  }

  String _exerciseCountToClipId(int n) {
    const ids = [
      'count_one_exercise',
      'count_two_exercises',
      'count_three_exercises',
      'count_four_exercises',
      'count_five_exercises',
      'count_six_exercises',
      'count_seven_exercises',
      'count_eight_exercises',
      'count_nine_exercises',
      'count_ten_exercises',
    ];
    return ids[n.clamp(1, 10) - 1];
  }

  String _durationToClipId(int minutes) {
    if (minutes <= 20) return 'duration_15min';
    if (minutes <= 37) return 'duration_30min';
    if (minutes <= 52) return 'duration_45min';
    if (minutes <= 67) return 'duration_60min';
    if (minutes <= 82) return 'duration_75min';
    return 'duration_90min';
  }

  String _randomOpeningBookend() {
    const ids = ['bookend_lets_get_to_work', 'bookend_lets_get_started'];
    return ids[_random.nextInt(ids.length)];
  }

  AudioClipSpec _randomEncouragement() {
    const ids = [
      'encourage_good_work', 'encourage_well_done', 'encourage_solid_set', 'encourage_nice_work',
      'encourage_great_effort', 'encourage_hows_done', 'encourage_strong_set', 'encourage_finding_rhythm',
    ];
    final id = ids[_random.nextInt(ids.length)];
    return AudioClipSpec.modular(category: _encouragement, modularId: id);
  }

  AudioClipSpec _weightDirectionClip(double? current, double? next) {
    if (next == null || current == null) {
      return const AudioClipSpec.modular(category: _weightDirection, modularId: 'weight_same');
    }
    if (next > current) {
      return const AudioClipSpec.modular(category: _weightDirection, modularId: 'weight_increase');
    }
    if (next < current) {
      return const AudioClipSpec.modular(category: _weightDirection, modularId: 'weight_decrease');
    }
    return const AudioClipSpec.modular(category: _weightDirection, modularId: 'weight_same');
  }

  /// Template 5 — declarative set labels (its_your_*); 7+ → next_set.
  AudioClipSpec _setSequencingClipTemplate5Declarative(int setIndex1Based) {
    if (setIndex1Based <= 1) {
      return const AudioClipSpec.modular(category: _setSequencing, modularId: 'its_your_first_set');
    }
    if (setIndex1Based <= 6) {
      const ids = [
        'its_your_second_set',
        'its_your_third_set',
        'its_your_fourth_set',
        'its_your_fifth_set',
        'its_your_sixth_set',
      ];
      return AudioClipSpec.modular(
        category: _setSequencing,
        modularId: ids[setIndex1Based - 2],
      );
    }
    return const AudioClipSpec.modular(category: _setSequencing, modularId: 'next_set');
  }
}
