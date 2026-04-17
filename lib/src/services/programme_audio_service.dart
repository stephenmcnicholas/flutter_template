import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'package:fytter/src/data/type_c_tts_client.dart';
import 'package:fytter/src/domain/program.dart';
import 'package:fytter/src/domain/program_repository.dart';

/// Generates and resolves programme description audio (Type C) and per-workout
/// spoken intros. Local: [documents]/audio/programmes/. Remote: Firebase Storage
/// under `audio/users/{userId}/programmes/...`.
///
/// TTS: Gemini Pro TTS via callable [synthesizeTypeCTts] — voice/model aligned with
/// [TtsConfig] and `docs/DECISIONS.md`. Generation fails silently when offline or
/// when the server key is not configured.
class ProgrammeAudioService {
  ProgrammeAudioService({
    ProgramRepository? programRepository,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
    TypeCTtsClient? typeCTtsClient,
  })  : _programRepository = programRepository,
        _storage = storage ?? FirebaseStorage.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _ttsClient = typeCTtsClient ?? TypeCTtsClient();

  final ProgramRepository? _programRepository;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;
  final TypeCTtsClient _ttsClient;

  static const String _subdir = 'audio/programmes';

  /// Current format is WAV (Gemini TTS). Legacy `.mp3` names may still exist locally.
  static String _programmeFileNameWav(String programId) => 'programme_$programId.wav';
  static String _programmeFileNameMp3(String programId) => 'programme_$programId.mp3';
  static String _workoutIntroFileNameWav(String workoutId) => 'workout_${workoutId}_intro.wav';
  static String _workoutIntroFileNameMp3(String workoutId) => 'workout_${workoutId}_intro.mp3';

  /// Expected local path for a workout intro (may not exist until TTS runs).
  Future<String> expectedWorkoutIntroLocalPath(String workoutId) async {
    final dir = await _programmesDir();
    return '${dir.path}/${_workoutIntroFileNameWav(workoutId)}';
  }

  String? get _uid => _auth.currentUser?.uid;

  Future<Directory> _programmesDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/$_subdir');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Deletes local programme audio and remote Storage object for [programId].
  Future<void> deleteProgrammeAudio(String programId, {Program? program}) async {
    try {
      final dir = await _programmesDir();
      for (final name in [
        _programmeFileNameWav(programId),
        _programmeFileNameMp3(programId),
      ]) {
        final file = File('${dir.path}/$name');
        if (await file.exists()) await file.delete();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[ProgrammeAudio] delete local programme failed: $e');
    }
    final remote = program?.programmeDescriptionAudioRemotePath;
    if (remote != null && remote.isNotEmpty) {
      try {
        await _storage.ref(remote).delete();
      } catch (e) {
        if (kDebugMode) debugPrint('[ProgrammeAudio] delete remote programme description: $e');
      }
    }
  }

  /// Returns local path if present; else downloads from [Program.programmeDescriptionAudioRemotePath].
  Future<String?> getProgrammeAudioPath(String programId) async {
    try {
      final dir = await _programmesDir();
      for (final name in [
        _programmeFileNameWav(programId),
        _programmeFileNameMp3(programId),
      ]) {
        final file = File('${dir.path}/$name');
        if (await file.exists()) return file.path;
      }

      if (_programRepository == null) return null;
      final program = await _programRepository.findById(programId);
      final remote = program.programmeDescriptionAudioRemotePath;
      if (remote == null || remote.isEmpty) return null;
      final out = File('${dir.path}/${_programmeFileNameWav(programId)}');
      await _storage.ref(remote).writeToFile(out);
      if (await out.exists()) return out.path;
    } catch (e) {
      if (kDebugMode) debugPrint('[ProgrammeAudio] getProgrammeAudioPath failed: $e');
    }
    return null;
  }

  /// Deletes the workout intro file for [workoutId] if it exists.
  Future<void> deleteWorkoutIntro(String workoutId, {String? introAudioRemotePath}) async {
    if (workoutId.isEmpty) return;
    try {
      final dir = await _programmesDir();
      for (final name in [
        _workoutIntroFileNameWav(workoutId),
        _workoutIntroFileNameMp3(workoutId),
      ]) {
        final file = File('${dir.path}/$name');
        if (await file.exists()) await file.delete();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[ProgrammeAudio] deleteWorkoutIntro local failed: $e');
    }
    if (introAudioRemotePath != null && introAudioRemotePath.isNotEmpty) {
      try {
        await _storage.ref(introAudioRemotePath).delete();
      } catch (e) {
        if (kDebugMode) debugPrint('[ProgrammeAudio] delete remote intro: $e');
      }
    }
  }

  Future<void> deleteAllWorkoutIntrosForProgramme(
    Iterable<String> workoutIds, {
    Map<String, String>? workoutIdToRemoteIntroPath,
  }) async {
    for (final id in workoutIds) {
      await deleteWorkoutIntro(
        id,
        introAudioRemotePath: workoutIdToRemoteIntroPath?[id],
      );
    }
  }

  /// Returns local path if present; else downloads using [introAudioRemotePath] from DB breakdowns.
  Future<String?> getWorkoutIntroPath(String workoutId) async {
    if (workoutId.isEmpty) return null;
    try {
      final dir = await _programmesDir();
      for (final name in [
        _workoutIntroFileNameWav(workoutId),
        _workoutIntroFileNameMp3(workoutId),
      ]) {
        final file = File('${dir.path}/$name');
        if (await file.exists()) return file.path;
      }

      final remote = await _findIntroRemotePathForWorkout(workoutId);
      if (remote == null || remote.isEmpty) return null;
      final out = File('${dir.path}/${_workoutIntroFileNameWav(workoutId)}');
      await _storage.ref(remote).writeToFile(out);
      if (await out.exists()) return out.path;
    } catch (e) {
      if (kDebugMode) debugPrint('[ProgrammeAudio] getWorkoutIntroPath failed: $e');
    }
    return null;
  }

  Future<String?> _findIntroRemotePathForWorkout(String workoutId) async {
    if (_programRepository == null) return null;
    final programs = await _programRepository.findAll();
    for (final p in programs) {
      final jsonStr = p.workoutBreakdowns;
      if (jsonStr == null || jsonStr.trim().isEmpty) continue;
      try {
        final list = jsonDecode(jsonStr) as List<dynamic>;
        for (final item in list) {
          final map = Map<String, dynamic>.from(item as Map);
          if (map['workoutId'] == workoutId) {
            final r = map['introAudioRemotePath'] as String?;
            if (r != null && r.isNotEmpty) return r;
          }
        }
      } catch (_) {}
    }
    return null;
  }

  /// Deletes programme + all workout intro locals and remotes parsed from [program].
  Future<void> deleteProgrammeAudioBundle(Program program) async {
    await deleteProgrammeAudio(program.id, program: program);
    final ids = <String>[];
    final remoteById = <String, String>{};
    final jsonStr = program.workoutBreakdowns;
    if (jsonStr != null && jsonStr.trim().isNotEmpty) {
      try {
        final list = jsonDecode(jsonStr) as List<dynamic>;
        for (final item in list) {
          final map = Map<String, dynamic>.from(item as Map);
          final wid = map['workoutId'] as String? ?? '';
          if (wid.isEmpty) continue;
          ids.add(wid);
          final r = map['introAudioRemotePath'] as String?;
          if (r != null && r.isNotEmpty) remoteById[wid] = r;
        }
      } catch (_) {}
    }
    for (final wid in program.schedule.map((w) => w.workoutId)) {
      if (!ids.contains(wid)) ids.add(wid);
    }
    await deleteAllWorkoutIntrosForProgramme(ids, workoutIdToRemoteIntroPath: remoteById);
  }

  static String _truncateForTts(String text, {int maxChars = 8000}) {
    final t = text.trim();
    if (t.length <= maxChars) return t;
    return '${t.substring(0, maxChars)}…';
  }

  Future<String?> _synthesizeToFile(String fileName, String sourceText) async {
    final bytes = await _ttsClient.synthesizeToWavBytes(_truncateForTts(sourceText));
    if (bytes == null || bytes.isEmpty) return null;
    final dir = await _programmesDir();
    final path = '${dir.path}/$fileName';
    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  }

  /// Generates programme description audio and saves locally. Returns file path on success.
  /// Call [uploadProgrammeDescriptionToStorage] after a non-null path, then persist remote path on [Program].
  Future<String?> generateAndSave(String programId, String descriptionText) async {
    if (descriptionText.trim().isEmpty) return null;
    try {
      return _synthesizeToFile(_programmeFileNameWav(programId), descriptionText);
    } catch (e) {
      if (kDebugMode) debugPrint('[ProgrammeAudio] generateAndSave failed: $e');
      return null;
    }
  }

  /// After a local file exists at [localPath], upload to Storage and return storage path.
  Future<String?> uploadProgrammeDescriptionToStorage(String programId, String localPath) async {
    final uid = _uid;
    if (uid == null) return null;
    try {
      final file = File(localPath);
      if (!await file.exists()) return null;
      final path = 'audio/users/$uid/programmes/$programId/description.wav';
      final ref = _storage.ref(path);
      await ref.putFile(file, SettableMetadata(contentType: 'audio/wav'));
      return path;
    } catch (e) {
      if (kDebugMode) debugPrint('[ProgrammeAudio] upload programme description failed: $e');
      return null;
    }
  }

  /// After a local workout intro file exists, upload and return storage path.
  Future<String?> uploadWorkoutIntroToStorage(
    String programId,
    String workoutId,
    String localPath,
  ) async {
    final uid = _uid;
    if (uid == null) return null;
    try {
      final file = File(localPath);
      if (!await file.exists()) return null;
      final path = 'audio/users/$uid/programmes/$programId/workouts/$workoutId/intro.wav';
      final ref = _storage.ref(path);
      await ref.putFile(file, SettableMetadata(contentType: 'audio/wav'));
      return path;
    } catch (e) {
      if (kDebugMode) debugPrint('[ProgrammeAudio] upload workout intro failed: $e');
      return null;
    }
  }

  /// Generates one workout intro; returns spoken text to persist on breakdown (`spokenIntro`).
  Future<String?> generateAndSaveWorkoutIntro(String workoutId, String briefDescription) async {
    if (workoutId.isEmpty || briefDescription.trim().isEmpty) return null;
    try {
      final path = await _synthesizeToFile(
        _workoutIntroFileNameWav(workoutId),
        briefDescription,
      );
      if (path == null) return null;
      return briefDescription.trim();
    } catch (e) {
      if (kDebugMode) debugPrint('[ProgrammeAudio] generateAndSaveWorkoutIntro failed: $e');
      return null;
    }
  }

  Future<String?> generateWorkoutIntroFromText(String workoutId, String spokenIntroText) async {
    if (workoutId.isEmpty || spokenIntroText.trim().isEmpty) return null;
    try {
      final path = await _synthesizeToFile(
        _workoutIntroFileNameWav(workoutId),
        spokenIntroText,
      );
      if (path == null) return null;
      return spokenIntroText.trim();
    } catch (e) {
      if (kDebugMode) debugPrint('[ProgrammeAudio] generateWorkoutIntroFromText failed: $e');
      return null;
    }
  }
}
