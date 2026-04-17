import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/data/type_c_tts_client.dart';
import 'package:fytter/src/domain/program_repository.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/services/programme_audio_service.dart';

/// Status of programme description audio for one program.
class ProgrammeAudioStatus {
  final bool isGenerating;
  final String? path;

  const ProgrammeAudioStatus({this.isGenerating = false, this.path});

  bool get isReady => path != null && !isGenerating;
}

/// Holds generating state and resolved path per program. Updated when generation completes.
class ProgrammeAudioNotifier extends StateNotifier<Map<String, ProgrammeAudioStatus>> {
  ProgrammeAudioNotifier(this._service, this._programRepository) : super({});

  final ProgrammeAudioService _service;
  final ProgramRepository _programRepository;

  /// Remove programme from state (e.g. when programme is deleted). Call after deleting the audio file.
  void removeProgram(String programId) {
    if (!state.containsKey(programId)) return;
    final next = Map<String, ProgrammeAudioStatus>.from(state)..remove(programId);
    state = next;
  }

  /// Start background generation for this program. Idempotent: if already generating, no-op.
  void startGeneration(String programId, String descriptionText) {
    if (state[programId]?.isGenerating == true) return;
    state = {...state, programId: const ProgrammeAudioStatus(isGenerating: true)};
    _runGeneration(programId, descriptionText);
  }

  /// Start per-workout intro generation in background (runs in parallel with programme audio).
  /// Parses workoutBreakdowns, generates intro for each workout, merges spokenIntro into breakdowns, saves program.
  void startWorkoutIntroGenerations(String programId) {
    _runWorkoutIntroGenerations(programId);
  }

  Future<void> _runGeneration(String programId, String descriptionText) async {
    var path = await _service.generateAndSave(programId, descriptionText);
    if (path != null) {
      final remote = await _service.uploadProgrammeDescriptionToStorage(programId, path);
      if (remote != null) {
        final p = await _programRepository.findById(programId);
        await _programRepository.save(
          p.copyWith(programmeDescriptionAudioRemotePath: remote),
        );
      }
    } else {
      path = await _service.getProgrammeAudioPath(programId);
    }
    state = {
      ...state,
      programId: ProgrammeAudioStatus(isGenerating: false, path: path),
    };
  }

  Future<void> _runWorkoutIntroGenerations(String programId) async {
    try {
      final program = await _programRepository.findById(programId);
      final jsonStr = program.workoutBreakdowns;
      if (jsonStr == null || jsonStr.trim().isEmpty) return;
      final breakdowns = jsonDecode(jsonStr) as List<dynamic>;
      final results = await Future.wait(
        breakdowns.map((e) async {
          final map = Map<String, dynamic>.from(e as Map<String, dynamic>);
          final workoutId = map['workoutId'] as String? ?? '';
          final briefDescription = map['briefDescription'] as String? ?? '';
          final spokenIntro =
              await _service.generateAndSaveWorkoutIntro(workoutId, briefDescription);
          String? introRemote;
          final expectedIntro = await _service.expectedWorkoutIntroLocalPath(workoutId);
          if (File(expectedIntro).existsSync()) {
            introRemote = await _service.uploadWorkoutIntroToStorage(
              programId,
              workoutId,
              expectedIntro,
            );
          }
          return (map, spokenIntro, introRemote);
        }),
      );
      final updated = results.map((r) {
        final map = r.$1;
        if (r.$2 != null) map['spokenIntro'] = r.$2;
        if (r.$3 != null) map['introAudioRemotePath'] = r.$3;
        return map;
      }).toList();
      final updatedJson = jsonEncode(updated);
      await _programRepository.save(program.copyWith(workoutBreakdowns: updatedJson));
    } catch (_) {
      // Fail silently; workout intros are additive
    }
  }

  /// Refresh path from disk (e.g. after app restart). Does not set generating.
  Future<void> refreshPath(String programId) async {
    final path = await _service.getProgrammeAudioPath(programId);
    final current = state[programId];
    if (current == null && path == null) return;
    state = {
      ...state,
      programId: ProgrammeAudioStatus(isGenerating: current?.isGenerating ?? false, path: path),
    };
  }
}

final programmeAudioServiceProvider = Provider<ProgrammeAudioService>((ref) {
  return ProgrammeAudioService(
    programRepository: ref.read(programRepositoryProvider),
    typeCTtsClient: ref.read(typeCTtsClientProvider),
  );
});

final programmeAudioNotifierProvider =
    StateNotifierProvider<ProgrammeAudioNotifier, Map<String, ProgrammeAudioStatus>>((ref) {
  return ProgrammeAudioNotifier(
    ref.read(programmeAudioServiceProvider),
    ref.read(programRepositoryProvider),
  );
});

/// Combined status for a program: from notifier (generating/ready) or from disk. Use in UI.
Future<ProgrammeAudioStatus> _statusFor(
  Ref ref,
  String programId,
  Map<String, ProgrammeAudioStatus> notifierState,
) async {
  final fromNotifier = notifierState[programId];
  if (fromNotifier != null) return fromNotifier;
  final service = ref.read(programmeAudioServiceProvider);
  final path = await service.getProgrammeAudioPath(programId);
  return ProgrammeAudioStatus(path: path);
}

/// Async status for a program. Recomputes when notifier state changes (e.g. generation completes).
final programmeAudioStatusProvider =
    FutureProvider.family<ProgrammeAudioStatus, String>((ref, programId) async {
  final notifierState = ref.watch(programmeAudioNotifierProvider);
  return _statusFor(ref, programId, notifierState);
});
