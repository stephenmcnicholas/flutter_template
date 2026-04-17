import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fytter/src/services/audio/audio_clip_paths.dart';
import 'package:fytter/src/services/audio/audio_coaching_timing.dart';
import 'package:fytter/src/services/audio/audio_service.dart';

/// Stitches notification audio by concatenating MP3 byte streams with a short
/// silent MP3 segment between clips (no ffmpeg — avoids retired native pods).
///
/// MP3 frames are self-delimiting; naive concat is sufficient for short cues.
class AudioAssemblyService {
  AudioAssemblyService({
    required AudioClipPaths clipPaths,
    /// When set (e.g. in tests), skips [getTemporaryDirectory] which can hang under `flutter_tester`.
    Directory? assemblyWorkDirectory,
  })  : _clipPaths = clipPaths,
        _assemblyWorkDirectory = assemblyWorkDirectory;

  final AudioClipPaths _clipPaths;
  final Directory? _assemblyWorkDirectory;

  /// Bundled silent segment (~[kCoachingInterClipSilenceMs] ms). Generate with:
  /// `ffmpeg -f lavfi -i anullsrc=r=44100:cl=mono -t 0.175 -c:a libmp3lame -q:a 4 silence_175ms.mp3`
  static const String silenceGapAssetPath = 'assets/audio/assembly/silence_175ms.mp3';

  /// Temp output filename for rest-end notification. Overwritten each time.
  static const String notificationTempFileName = 'rest_end_audio.mp3';

  /// Same as [kCoachingInterClipSilenceMs] (kept for call sites / docs).
  static int get silenceMs => kCoachingInterClipSilenceMs;

  Future<String?> assembleToTempFile(
    List<AudioClipSpec> specs, {
    required bool skipMissingModular,
    required bool skipEntireCueIfAnyExerciseMissing,
  }) async {
    final resolved = <String>[];
    for (final spec in specs) {
      String? path;
      if (spec.isModular) {
        path = await _clipPaths.resolveModular(spec.category!, spec.modularId!);
        if (path == null && skipMissingModular) {
          if (kDebugMode) debugPrint('[AudioCoaching] Skipping missing modular in assembly');
          continue;
        }
      } else if (spec.isSentence) {
        path = await _clipPaths.resolveSentence(spec.sentenceId!, spec.variant!);
        if (path == null && skipEntireCueIfAnyExerciseMissing) {
          if (kDebugMode) debugPrint('[AudioCoaching] Missing sentence clip, skipping entire cue');
          return null;
        }
      } else {
        path = await _clipPaths.resolveExercise(spec.exerciseId!, spec.cueType!);
        if (path == null && skipEntireCueIfAnyExerciseMissing) {
          if (kDebugMode) debugPrint('[AudioCoaching] Missing exercise clip, skipping entire cue');
          return null;
        }
      }
      if (path != null) resolved.add(path);
    }
    return _assembleResolvedPaths(resolved);
  }

  /// Host validation / tests: skips async [AudioClipPaths.resolveModular] (can hang under `flutter_tester`).
  @visibleForTesting
  Future<String?> assembleFromResolvedFilePaths(List<String> resolvedPaths) =>
      _assembleResolvedPaths(resolvedPaths);

  Future<String?> _assembleResolvedPaths(List<String> resolved) async {
    if (resolved.isEmpty) return null;

    final gapBytes = await _clipPaths.loadAssetBytes(silenceGapAssetPath);
    if (gapBytes == null || gapBytes.isEmpty) {
      if (kDebugMode) {
        debugPrint('[AudioCoaching] Missing silence gap asset: $silenceGapAssetPath');
      }
    }

    final clipBytes = <Uint8List>[];
    for (final p in resolved) {
      final bytes = await _readClipBytes(p);
      if (bytes != null && bytes.isNotEmpty) {
        clipBytes.add(bytes);
      }
    }
    if (clipBytes.isEmpty) return null;

    final tempDir = _assemblyWorkDirectory ?? await getTemporaryDirectory();
    final audioDir = Directory('${tempDir.path}/audio');
    if (!audioDir.existsSync()) audioDir.createSync(recursive: true);
    final outputPath = '${audioDir.path}/$notificationTempFileName';

    if (clipBytes.length == 1) {
      File(outputPath).writeAsBytesSync(clipBytes.first);
      return outputPath;
    }

    final gap = gapBytes ?? Uint8List(0);
    final out = BytesBuilder(copy: false);
    for (var i = 0; i < clipBytes.length; i++) {
      out.add(clipBytes[i]);
      if (i < clipBytes.length - 1 && gap.isNotEmpty) {
        out.add(gap);
      }
    }
    File(outputPath).writeAsBytesSync(out.takeBytes());
    return outputPath;
  }

  Future<Uint8List?> _readClipBytes(String path) async {
    if (path.startsWith('assets/')) {
      return _clipPaths.loadAssetBytes(path);
    }
    try {
      final f = File(path);
      if (f.existsSync()) return f.readAsBytesSync();
    } catch (e) {
      if (kDebugMode) debugPrint('[AudioCoaching] Failed to read clip $path: $e');
    }
    return null;
  }
}
