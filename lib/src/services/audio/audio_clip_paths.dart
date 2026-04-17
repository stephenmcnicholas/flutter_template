import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:fytter/src/services/audio/coaching_audio_tier.dart';

/// Resolves paths for modular (Type A) and exercise-specific (Type B) audio clips
/// from the app documents directory (downloaded from Firebase Storage — not bundled).
///
/// Bundled assets (e.g. assembly gap) still load via [assetBundle].
class AudioClipPaths {
  AudioClipPaths({AssetBundle? assetBundle}) : _bundle = assetBundle ?? rootBundle;

  final AssetBundle _bundle;

  Directory? _documentsDirectory;
  CoachingAudioTier? _sessionCoachingTier;

  /// Set once at workout start from the scorecard; used for Type B paths until cleared.
  void setSessionCoachingTier(CoachingAudioTier tier) {
    _sessionCoachingTier = tier;
  }

  void clearSessionCoachingTier() {
    _sessionCoachingTier = null;
  }

  CoachingAudioTier get sessionCoachingTierOrBeginner =>
      _sessionCoachingTier ?? CoachingAudioTier.beginner;

  Future<Directory> _documentsDir() async {
    _documentsDirectory ??= await getApplicationDocumentsDirectory();
    return _documentsDirectory!;
  }

  String _modularFilePath(Directory doc, String category, String clipId) =>
      p.join(doc.path, 'audio', 'modular', category, '$clipId.mp3');

  String _exerciseFilePath(Directory doc, String tierName, String exerciseId, String cueType) =>
      p.join(doc.path, 'audio', 'exercises', tierName, exerciseId, '$cueType.mp3');

  String _sentenceFilePath(Directory doc, String sentenceId, String variant) =>
      p.join(doc.path, 'audio', 'sentences', '${sentenceId}_$variant.mp3');

  /// Modular clip: `{documents}/audio/modular/{category}/{clipId}.mp3`
  Future<String?> resolveModular(String category, String clipId) async {
    final doc = await _documentsDir();
    final path = _modularFilePath(doc, category, clipId);
    final exists = File(path).existsSync();
    if (!exists && kDebugMode) {
      debugPrint('[AudioCoaching] Missing modular clip (documents): $path');
    }
    return exists ? path : null;
  }

  /// Sentence clip (Type B): `{documents}/audio/sentences/{sentenceId}_{variant}.mp3`
  /// Firebase Storage: `audio/sentences/{sentenceId}_{variant}.mp3`
  Future<String?> resolveSentence(String sentenceId, String variant) async {
    final doc = await _documentsDir();
    final path = _sentenceFilePath(doc, sentenceId, variant);
    final exists = File(path).existsSync();
    if (!exists && kDebugMode) {
      debugPrint('[AudioCoaching] Missing sentence clip (documents): $path');
    }
    return exists ? path : null;
  }

  /// Exercise clip: `{documents}/audio/exercises/{tier}/{exerciseId}/{cueType}.mp3`
  /// Uses [setSessionCoachingTier] for this workout session; defaults to beginner.
  Future<String?> resolveExercise(String exerciseId, String cueType) async {
    final doc = await _documentsDir();
    final tierName = coachingTierStorageName(sessionCoachingTierOrBeginner);
    final path = _exerciseFilePath(doc, tierName, exerciseId, cueType);
    final exists = File(path).existsSync();
    if (!exists && kDebugMode) {
      debugPrint('[AudioCoaching] Missing exercise clip (documents): $path');
    }
    return exists ? path : null;
  }

  /// Load bytes: bundled `assets/...` via [AssetBundle], otherwise local file.
  Future<Uint8List?> loadAssetBytes(String path) async {
    if (path.startsWith('assets/')) {
      try {
        final data = await _bundle.load(path);
        return data.buffer.asUint8List();
      } catch (_) {
        return null;
      }
    }
    try {
      final f = File(path);
      if (f.existsSync()) return f.readAsBytesSync();
    } catch (_) {}
    return null;
  }

  AssetBundle get assetBundle => _bundle;
}
