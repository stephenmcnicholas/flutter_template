import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/providers/audio_coaching_settings_provider.dart';
import 'package:fytter/src/providers/premium_provider.dart';
import 'package:fytter/src/services/audio/audio_assembly_service.dart';
import 'package:fytter/src/services/audio/audio_clip_paths.dart';
import 'package:fytter/src/services/audio/audio_download_service.dart';
import 'package:fytter/src/services/audio/audio_service.dart';
import 'package:fytter/src/services/audio/audio_template_engine.dart';
import 'package:fytter/src/services/audio/sentence_library.dart';
import 'package:fytter/src/providers/programme_audio_provider.dart';
import 'package:fytter/src/services/audio/rest_timer_audio_scheduler.dart';

final audioClipPathsProvider = Provider<AudioClipPaths>((ref) {
  return AudioClipPaths(assetBundle: rootBundle);
});

/// Sentence catalog for Type B coaching (UI + clip resolution). Loaded once from assets.
final sentenceLibraryProvider = FutureProvider<SentenceLibrary>((ref) async {
  return SentenceLibrary.loadFromAssets(rootBundle);
});

final audioDownloadServiceProvider = Provider<AudioDownloadService>((ref) {
  return AudioDownloadService(assetBundle: rootBundle);
});

final audioTemplateEngineProvider = Provider<AudioTemplateEngine>((ref) {
  return AudioTemplateEngine();
});

final audioAssemblyServiceProvider = Provider<AudioAssemblyService>((ref) {
  return AudioAssemblyService(clipPaths: ref.watch(audioClipPathsProvider));
});

final audioServiceProvider = Provider<AudioServiceInterface>((ref) {
  final programmeAudio = ref.watch(programmeAudioServiceProvider);
  return AudioService(
    clipPaths: ref.watch(audioClipPathsProvider),
    getWorkoutIntroPath: programmeAudio.getWorkoutIntroPath,
  );
});

/// Scheduler for rest-end notification with Template 5 audio. Null if dependencies unavailable.
final restTimerAudioSchedulerProvider = Provider<RestTimerAudioSchedulerBase?>((ref) {
  final assembly = ref.watch(audioAssemblyServiceProvider);
  final engine = ref.watch(audioTemplateEngineProvider);
  final premium = ref.read(premiumServiceProvider);
  final settings = ref.read(audioCoachingSettingsProvider);
  final clipPaths = ref.read(audioClipPathsProvider);
  return RestTimerAudioScheduler(
    assemblyService: assembly,
    templateEngine: engine,
    isPremium: () => premium.isPremium(),
    isGuidedMode: () => settings.isGuided,
    getSentenceLibrary: () => ref.read(sentenceLibraryProvider.future),
    getCoachingTier: () => clipPaths.sessionCoachingTierOrBeginner,
  );
});
