import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fytter/src/domain/exercise_instructions.dart';
import 'package:fytter/src/services/audio/coaching_audio_tier.dart';
import 'package:fytter/src/services/audio/sentence_library.dart';

/// Tracks Type A + sentence (Type B) downloads, lazy workout fetch, graduation.
///
/// Does not block the workout — callers should [unawaited] fire-and-forget.
class AudioDownloadService {
  AudioDownloadService({
    FirebaseStorage? storage,
    AssetBundle? assetBundle,
  })  : _storage = storage ?? FirebaseStorage.instance,
        _bundle = assetBundle ?? rootBundle;

  final FirebaseStorage _storage;
  final AssetBundle _bundle;

  /// Bump this when new modular categories are added to Firebase Storage.
  /// Existing installs with an older version will re-run the modular download
  /// (already-present files are skipped; only new files are fetched).
  static const int _typeALibraryVersion = 3; // bumped: added duration_15min clip

  static const String prefTypeADownloaded = 'audio_type_a_downloaded'; // legacy bool, no longer used as gate
  static const String prefTypeAVersion = 'audio_type_a_version';
  static const String prefLastCoachingTier = 'audio_last_coaching_tier';
  static const String prefCachedSentences = 'audio_cached_sentences';

  /// Max object size for [Reference.getData] (MP3 clips).
  static const int _maxClipBytes = 10 * 1024 * 1024;

  SentenceLibrary? _sentenceLibrary;

  /// Serialize prefs read-modify-write for [prefCachedSentences] (parallel downloads).
  Future<void> _cacheWriteChain = Future<void>.value();

  void _enqueueCachedSentenceKey(String key) {
    _cacheWriteChain = _cacheWriteChain.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      final set = _readCachedSentenceKeys(prefs);
      if (set.contains(key)) return;
      set.add(key);
      await _writeCachedSentenceKeys(prefs, set);
    });
  }

  Future<SentenceLibrary> _sentenceLibraryLoaded() async {
    _sentenceLibrary ??= SentenceLibrary.fromJsonString(
      await _bundle.loadString('assets/exercises/sentences.json'),
    );
    return _sentenceLibrary!;
  }

  /// TRIGGER 1 — Premium: download all Type A modular clips from `audio/modular/...`.
  Future<void> triggerTypeADownloadOnPremiumActivation() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getInt(prefTypeAVersion) == _typeALibraryVersion) return;
    if (!_firebaseReady()) return;

    try {
      final ok = await _downloadAllModularUnderStoragePrefix('audio/modular');
      if (ok) {
        await prefs.setInt(prefTypeAVersion, _typeALibraryVersion);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AudioDownload] Type A download failed: $e');
    }
  }

  /// TRIGGER 2 — Workout start (premium): lazy sentence clips for this workout + tier.
  Future<void> triggerTypeBDownloadForWorkout({
    required CoachingAudioTier tier,
    required Iterable<String> exerciseIds,
  }) async {
    if (!_firebaseReady()) return;
    try {
      final lib = await _sentenceLibraryLoaded();
      final instructionsMap = await _loadInstructionsMap();
      final tierName = coachingTierStorageName(tier);
      final keys = _collectSentenceKeysForExercises(
        exerciseIds: exerciseIds,
        instructionsMap: instructionsMap,
        tierName: tierName,
        lib: lib,
      );
      final prefs = await SharedPreferences.getInstance();
      final cached = _readCachedSentenceKeys(prefs);
      for (final key in keys) {
        if (cached.contains(key)) continue;
        unawaited(_downloadSentenceClip(key));
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AudioDownload] Type B sentence download failed: $e');
    }
  }

  /// TRIGGER 3 — Graduation: download clips needed for [nextTierName]; no local deletion
  /// (sentence files are shared across tiers).
  Future<void> triggerGraduationSwap({
    required String previousTierName,
    required String nextTierName,
    required Iterable<String> exerciseIds,
  }) async {
    if (!_firebaseReady()) return;
    if (previousTierName == nextTierName) return;
    try {
      final lib = await _sentenceLibraryLoaded();
      final instructionsMap = await _loadInstructionsMap();
      final keys = _collectSentenceKeysForExercises(
        exerciseIds: exerciseIds,
        instructionsMap: instructionsMap,
        tierName: nextTierName,
        lib: lib,
      );
      final prefs = await SharedPreferences.getInstance();
      final cached = _readCachedSentenceKeys(prefs);
      for (final key in keys) {
        if (cached.contains(key)) continue;
        unawaited(_downloadSentenceClip(key));
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AudioDownload] Graduation sentence download failed: $e');
    }
  }

  /// Call when scorecard tier may have changed (e.g. after programme generation).
  Future<void> syncTierChangeAndMaybeGraduate({
    required CoachingAudioTier newTier,
    required Iterable<String> nextProgramExerciseIds,
  }) async {
    if (!_firebaseReady()) return;
    final prefs = await SharedPreferences.getInstance();
    final newName = coachingTierStorageName(newTier);
    final previous = prefs.getString(prefLastCoachingTier);
    await prefs.setString(prefLastCoachingTier, newName);

    if (previous == null || previous == newName) return;
    await triggerGraduationSwap(
      previousTierName: previous,
      nextTierName: newName,
      exerciseIds: nextProgramExerciseIds,
    );
  }

  Future<bool> isTypeAMarkedDownloaded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(prefTypeAVersion) == _typeALibraryVersion;
  }

  // ——— Internals ———

  bool _firebaseReady() {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  bool _isNotFound(Object e) {
    if (e is FirebaseException) {
      return e.code == 'object-not-found';
    }
    return false;
  }

  bool _isNetworkish(Object e) {
    if (e is SocketException || e is TimeoutException) return true;
    if (e is FirebaseException) {
      return e.code == 'network-request-failed' ||
          e.code == 'cancelled' ||
          e.code == 'unknown';
    }
    return false;
  }

  /// Result of [getData] + disk write. [notFound] means 404 — safe to ignore for batch Type A.
  Future<({bool wrote, bool notFound})> _downloadRefBytesToFile(Reference ref, File dest) async {
    if (kDebugMode) {
      debugPrint('[AudioDownload] downloading ${ref.fullPath}');
    }
    try {
      final bytes = await ref.getData(_maxClipBytes);
      if (bytes == null || bytes.isEmpty) {
        if (kDebugMode) debugPrint('[AudioDownload] empty data (skip): ${ref.fullPath}');
        return (wrote: false, notFound: false);
      }
      if (!dest.parent.existsSync()) {
        dest.parent.createSync(recursive: true);
      }
      await dest.writeAsBytes(bytes, flush: true);
      if (kDebugMode) {
        debugPrint('[AudioDownload] saved to ${dest.path}');
      }
      return (wrote: true, notFound: false);
    } on FirebaseException catch (e) {
      if (_isNotFound(e)) {
        if (kDebugMode) debugPrint('[AudioDownload] not in Storage (skip): ${ref.fullPath}');
        return (wrote: false, notFound: true);
      }
      if (kDebugMode) {
        debugPrint('[AudioDownload] Firebase error ${ref.fullPath}: ${e.code} ${e.message}');
      }
      return (wrote: false, notFound: false);
    } catch (e) {
      if (_isNetworkish(e)) {
        if (kDebugMode) debugPrint('[AudioDownload] network/unavailable (skip): ${ref.fullPath} — $e');
        return (wrote: false, notFound: false);
      }
      if (e is FileSystemException) {
        if (kDebugMode) debugPrint('[AudioDownload] write failed ${dest.path}: $e');
        return (wrote: false, notFound: false);
      }
      if (kDebugMode) debugPrint('[AudioDownload] download failed ${ref.fullPath}: $e');
      return (wrote: false, notFound: false);
    }
  }

  Future<Map<String, ExerciseInstructions>> _loadInstructionsMap() async {
    final raw = await _bundle.loadString('assets/exercises/exercises.json');
    final list = json.decode(raw) as List<dynamic>;
    final map = <String, ExerciseInstructions>{};
    for (final item in list) {
      if (item is! Map<String, dynamic>) continue;
      final id = item['id'] as String?;
      final ins = item['instructions'] as Map<String, dynamic>?;
      if (id == null || ins == null) continue;
      map[id] = ExerciseInstructions.fromJson(ins);
    }
    return map;
  }

  Set<String> _collectSentenceKeysForExercises({
    required Iterable<String> exerciseIds,
    required Map<String, ExerciseInstructions> instructionsMap,
    required String tierName,
    required SentenceLibrary lib,
  }) {
    final out = <String>{};
    for (final eid in exerciseIds) {
      final ins = instructionsMap[eid];
      if (ins == null) continue;
      _collectCueField(ins.setup, tierName, lib, out);
      _collectCueField(ins.movement, tierName, lib, out);
      if (ins.goodFormFeels != null) {
        _collectCueField(ins.goodFormFeels!, tierName, lib, out);
      }
      if (ins.breathingCue != null) {
        _collectCueField(ins.breathingCue!, tierName, lib, out);
      }
      for (final fix in ins.commonFixes) {
        _collectCommonFix(fix, tierName, lib, out);
      }
    }
    return out;
  }

  void _collectCueField(
    ExerciseCueField field,
    String tierName,
    SentenceLibrary lib,
    Set<String> out,
  ) {
    final indices = field.tiers[tierName];
    if (indices == null) return;
    for (final i in indices) {
      if (i < 0 || i >= field.sentences.length) continue;
      final sid = field.sentences[i];
      _addVariantsForSentence(sid, lib, out);
    }
  }

  void _collectCommonFix(
    ExerciseCommonFix fix,
    String tierName,
    SentenceLibrary lib,
    Set<String> out,
  ) {
    final t = fix.tiers[tierName];
    if (t == null) return;
    if (t.issue && fix.issue.isNotEmpty) {
      _addVariantsForSentence(fix.issue, lib, out);
    }
    for (final idx in t.fix) {
      if (idx < 0 || idx >= fix.fix.length) continue;
      _addVariantsForSentence(fix.fix[idx], lib, out);
    }
  }

  void _addVariantsForSentence(String sentenceId, SentenceLibrary lib, Set<String> out) {
    final vars = lib.getVariants(sentenceId);
    if (vars.isEmpty) {
      out.add('${sentenceId}_mid');
      return;
    }
    for (final v in vars) {
      out.add('${sentenceId}_$v');
    }
  }

  Future<void> _downloadSentenceClip(String cacheKey) async {
    final lastUnderscore = cacheKey.lastIndexOf('_');
    if (lastUnderscore <= 0) return;
    final sentenceId = cacheKey.substring(0, lastUnderscore);
    final variant = cacheKey.substring(lastUnderscore + 1);
    final doc = await getApplicationDocumentsDirectory();
    final local = File(p.join(doc.path, 'audio', 'sentences', '${sentenceId}_$variant.mp3'));

    if (local.existsSync()) {
      _enqueueCachedSentenceKey(cacheKey);
      return;
    }

    final storagePath = 'audio/sentences/${sentenceId}_$variant.mp3';
    final ref = _storage.ref(storagePath);
    final r = await _downloadRefBytesToFile(ref, local);
    if (r.wrote) {
      _enqueueCachedSentenceKey(cacheKey);
    }
  }

  /// Lists `audio/modular/{category}/*.mp3` and downloads each. Returns `true` if no fatal error.
  Future<bool> _downloadAllModularUnderStoragePrefix(String prefix) async {
    var hadFailure = false;
    try {
      final root = _storage.ref(prefix);
      final list = await root.listAll();
      for (final categoryRef in list.prefixes) {
        final category = categoryRef.name;
        final files = await categoryRef.listAll();
        for (final fileRef in files.items) {
          final name = fileRef.name;
          if (!name.toLowerCase().endsWith('.mp3')) continue;
          final doc = await getApplicationDocumentsDirectory();
          final dest = File(p.join(doc.path, 'audio', 'modular', category, name));
          if (dest.existsSync()) continue;
          final r = await _downloadRefBytesToFile(fileRef, dest);
          if (!r.wrote && !r.notFound) hadFailure = true;
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AudioDownload] modular list/download failed: $e');
      return false;
    }
    return !hadFailure;
  }

  Set<String> _readCachedSentenceKeys(SharedPreferences prefs) {
    final raw = prefs.getString(prefCachedSentences);
    if (raw == null || raw.isEmpty) return <String>{};
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => e.toString()).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> _writeCachedSentenceKeys(SharedPreferences prefs, Set<String> keys) async {
    await prefs.setString(
      prefCachedSentences,
      jsonEncode(keys.toList()..sort()),
    );
  }
}
