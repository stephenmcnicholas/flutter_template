import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:fytter/src/domain/exercise_instructions.dart';
import 'package:fytter/src/services/audio/audio_assembly_service.dart';
import 'package:fytter/src/services/audio/audio_template_engine.dart';
import 'package:fytter/src/services/audio/coaching_audio_tier.dart';
import 'package:fytter/src/services/audio/sentence_library.dart';
import 'package:fytter/src/services/notification_service.dart';

/// Context passed when starting the rest timer so we can assemble Template 5
/// and schedule the rest-end notification with custom sound.
class RestTimerAudioContext {
  const RestTimerAudioContext({
    required this.exerciseId,
    required this.nextSetIndex1Based,
    required this.isFirstSetOfExercise,
    this.isLastSetOfExercise = false,
    this.instructions,
  });

  final String exerciseId;
  final int nextSetIndex1Based;
  final bool isFirstSetOfExercise;
  /// True when the upcoming set is the final set of this exercise.
  final bool isLastSetOfExercise;
  /// Null in on-demand mode — scheduler skips audio when absent.
  final ExerciseInstructions? instructions;
}

/// Abstract interface for the rest-timer audio scheduler.
/// Extracted to allow test doubles without heavy constructor dependencies.
abstract class RestTimerAudioSchedulerBase {
  void scheduleWhenRestStarts({
    required RestTimerAudioContext context,
    required DateTime restEndTime,
  });
}

/// When rest timer starts with [RestTimerAudioContext], assembles Template 5
/// and schedules a local notification to fire at rest end with that audio.
class RestTimerAudioScheduler extends RestTimerAudioSchedulerBase {
  RestTimerAudioScheduler({
    required AudioAssemblyService assemblyService,
    required AudioTemplateEngine templateEngine,
    required Future<bool> Function() isPremium,
    required bool Function() isGuidedMode,
    required Future<SentenceLibrary> Function() getSentenceLibrary,
    required CoachingAudioTier Function() getCoachingTier,
  })  : _assemblyService = assemblyService,
        _templateEngine = templateEngine,
        _isPremium = isPremium,
        _isGuidedMode = isGuidedMode,
        _getSentenceLibrary = getSentenceLibrary,
        _getCoachingTier = getCoachingTier;

  final AudioAssemblyService _assemblyService;
  final AudioTemplateEngine _templateEngine;
  final Future<bool> Function() _isPremium;
  final bool Function() _isGuidedMode;
  final Future<SentenceLibrary> Function() _getSentenceLibrary;
  final CoachingAudioTier Function() _getCoachingTier;

  @override
  void scheduleWhenRestStarts({
    required RestTimerAudioContext context,
    required DateTime restEndTime,
  }) {
    unawaited(_schedule(context, restEndTime));
  }

  Future<void> _schedule(RestTimerAudioContext context, DateTime restEndTime) async {
    try {
      final premium = await _isPremium();
      if (!premium || !_isGuidedMode()) return;

      final instructions = context.instructions;
      if (instructions == null) return;

      final sentences = await _getSentenceLibrary();
      final tier = _getCoachingTier();

      final specs = _templateEngine.template5RestEnd(
        exerciseId: context.exerciseId,
        setIndex1Based: context.nextSetIndex1Based,
        isFirstSetOfExercise: context.isFirstSetOfExercise,
        isLastSetOfExercise: context.isLastSetOfExercise,
        instructions: instructions,
        sentences: sentences,
        tier: tier,
      );

      final path = await _assemblyService.assembleToTempFile(
        specs,
        skipMissingModular: true,
        skipEntireCueIfAnyExerciseMissing: false,
      );

      await scheduleRestEndNotification(
        scheduledAt: restEndTime,
        customSoundPath: path,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[AudioCoaching] Rest-end notification schedule failed: $e');
    }
  }
}
