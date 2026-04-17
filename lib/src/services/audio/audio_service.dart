import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:fytter/src/services/audio/audio_clip_paths.dart';
import 'package:fytter/src/services/audio/audio_coaching_timing.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

/// Resolver for dynamic workout intro file path (Type C). Used by Template 1.
typedef WorkoutIntroPathResolver = Future<String?> Function(String workoutId);

/// Contract for in-app coaching audio. Extracted so tests can inject a fake
/// without touching [just_audio] or the device audio stack.
abstract class AudioServiceInterface {
  Future<void> startBackgroundSession();
  Future<void> stopBackgroundSession();
  Future<void> playPath(String? path);
  Future<void> playModular(String category, String clipId);
  Future<void> playExercise(String exerciseId, String cueType);
  Future<void> playSequence(List<AudioClipSpec> specs);
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  /// Cancels any in-progress sequence and pauses current playback without
  /// calling [stop] — this keeps the iOS AVAudioSession active so subsequent
  /// playback (e.g. the post-workout celebration chime) can start immediately.
  Future<void> cancelSequenceAndPause();
  void dispose();
}

/// Plays in-app audio for coaching. Skips missing clips; never throws.
/// Holds background audio session while a workout is active so notification
/// audio can play when the app is in background.
class AudioService implements AudioServiceInterface {
  AudioService({
    required AudioClipPaths clipPaths,
    AudioPlayer? player,
    WorkoutIntroPathResolver? getWorkoutIntroPath,
  })  : _clipPaths = clipPaths,
        _player = player ?? AudioPlayer(),
        _getWorkoutIntroPath = getWorkoutIntroPath;

  final AudioClipPaths _clipPaths;
  final AudioPlayer _player;
  final WorkoutIntroPathResolver? _getWorkoutIntroPath;

  bool _sessionActive = false;
  int _sequenceGeneration = 0;

  /// Start background audio session (call when workout begins).
  @override
  Future<void> startBackgroundSession() async {
    if (_sessionActive) return;
    // Configure the iOS AVAudioSession with the playback category so that
    // just_audio can start reliably and the session stays active between clips.
    final audioSession = await AudioSession.instance;
    await audioSession.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));
    await _player.setLoopMode(LoopMode.off);
    _sessionActive = true;
  }

  /// End background audio session (call when workout ends).
  @override
  Future<void> stopBackgroundSession() async {
    await _player.stop();
    _sessionActive = false;
  }

  /// Play a single clip by path (asset path or file path). If path is null, no-op.
  @override
  Future<void> playPath(String? path) async {
    if (path == null) return;
    try {
      // just_audio's setAsset uses a custom flaasset:// URL scheme on iOS that
      // fails with -11849 on iOS 18. Extract bundle assets to a temp file first
      // and play via setFilePath, which works identically to coaching audio.
      final filePath = path.startsWith('assets/')
          ? await _extractBundleAssetToFile(path)
          : path;
      await _player.setFilePath(filePath);
      await _player.play();
      await _player.processingStateStream
          .firstWhere((s) => s == ProcessingState.completed || s == ProcessingState.idle);
    } catch (e) {
      if (kDebugMode) debugPrint('[AudioCoaching] Play failed: $path — $e');
    }
  }

  /// Extracts a Flutter bundle asset to a temporary file and returns the path.
  /// Overwrites the cached file if the asset size has changed (handles updates).
  Future<String> _extractBundleAssetToFile(String assetPath) async {
    final dir = await getTemporaryDirectory();
    final fileName = assetPath.replaceAll('/', '_');
    final file = File('${dir.path}/$fileName');
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    if (!file.existsSync() || file.lengthSync() != bytes.length) {
      await file.writeAsBytes(bytes, flush: true);
    }
    return file.path;
  }

  /// Play a single modular clip. Skips if missing.
  @override
  Future<void> playModular(String category, String clipId) async {
    final path = await _clipPaths.resolveModular(category, clipId);
    await playPath(path);
  }

  /// Play a single exercise clip. Skips if missing.
  @override
  Future<void> playExercise(String exerciseId, String cueType) async {
    final path = await _clipPaths.resolveExercise(exerciseId, cueType);
    await playPath(path);
  }

  /// Play a sequence of clip specs. Specs can be modular, exercise, or workout intro (dynamic file).
  /// Missing clips are skipped. After each played clip, waits [kCoachingInterClipSilenceMs] before
  /// the next (no stitched file — sequential [just_audio] playback).
  /// Calling [stop] cancels any in-progress sequence immediately.
  @override
  Future<void> playSequence(List<AudioClipSpec> specs) async {
    final generation = _sequenceGeneration;
    var playedAny = false;
    for (final spec in specs) {
      if (_sequenceGeneration != generation) return;
      String? path;
      if (spec.isWorkoutIntro) {
        final wid = spec.workoutId;
        if (_getWorkoutIntroPath != null && wid != null && wid.isNotEmpty) {
          path = await _getWorkoutIntroPath(wid);
        }
      } else if (spec.isModular) {
        path = await _clipPaths.resolveModular(spec.category!, spec.modularId!);
      } else if (spec.isSentence) {
        path = await _clipPaths.resolveSentence(spec.sentenceId!, spec.variant!);
      } else {
        path = await _clipPaths.resolveExercise(spec.exerciseId!, spec.cueType!);
      }
      if (path == null) continue;
      if (_sequenceGeneration != generation) return;
      if (playedAny) {
        await Future<void>.delayed(
          Duration(milliseconds: kCoachingInterClipSilenceMs),
        );
        if (_sequenceGeneration != generation) return;
      }
      await playPath(path);
      playedAny = true;
    }
  }

  /// Pause current playback without losing position.
  @override
  Future<void> pause() async {
    await _player.pause();
  }

  /// Resume paused playback from current position.
  @override
  Future<void> resume() async {
    await _player.play();
  }

  /// Stop current playback, reset position, and cancel any in-progress sequence.
  @override
  Future<void> stop() async {
    _sequenceGeneration++;
    await _player.stop();
  }

  /// Cancels any in-progress sequence and pauses playback without calling
  /// [stop]. On iOS, [stop] causes just_audio to put the AVPlayer in idle,
  /// which can deactivate the AVAudioSession and prevent a subsequent
  /// [playPath] call from starting. [pause] keeps the session alive so the
  /// next clip (e.g. the celebration chime) can play without re-initialising
  /// a new native player instance.
  @override
  Future<void> cancelSequenceAndPause() async {
    _sequenceGeneration++;
    if (kDebugMode) debugPrint('[AudioCoaching] cancelSequenceAndPause — playerState=${_player.processingState}');
    await _player.pause();
    if (kDebugMode) debugPrint('[AudioCoaching] cancelSequenceAndPause done — playerState=${_player.processingState}');
  }

  @override
  void dispose() {
    _player.dispose();
  }
}

/// Spec for one clip in a sequence: modular, sentence (Type B library), legacy exercise cue,
/// or dynamic workout intro (file path resolved at playback).
class AudioClipSpec {
  const AudioClipSpec.modular({required this.category, required this.modularId})
      : exerciseId = null,
        cueType = null,
        workoutId = null,
        sentenceId = null,
        variant = null;

  const AudioClipSpec.exercise({required this.exerciseId, required this.cueType})
      : category = null,
        modularId = null,
        workoutId = null,
        sentenceId = null,
        variant = null;

  /// Type B sentence clip: `{sentenceId}_{variant}.mp3` under `audio/sentences/`.
  const AudioClipSpec.sentence({required this.sentenceId, required this.variant})
      : category = null,
        modularId = null,
        exerciseId = null,
        cueType = null,
        workoutId = null;

  /// Dynamic per-workout intro (Type C). Resolved to file path at playback; skip if missing.
  const AudioClipSpec.workoutIntro({required this.workoutId})
      : category = null,
        modularId = null,
        exerciseId = null,
        cueType = null,
        sentenceId = null,
        variant = null;

  final String? category;
  final String? modularId;
  final String? exerciseId;
  final String? cueType;
  final String? workoutId;
  final String? sentenceId;
  /// `mid` or `final` for sentence clips.
  final String? variant;

  bool get isModular => category != null && modularId != null;
  bool get isWorkoutIntro => workoutId != null;
  bool get isSentence => sentenceId != null && variant != null;
}
