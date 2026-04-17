import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/domain/program.dart';
import 'package:fytter/src/providers/premium_provider.dart';
import 'package:fytter/src/providers/programme_audio_provider.dart';

/// Text passed to Type C programme TTS — matches programme preview / start flow.
/// Prefers [Program.coachRationaleSpoken] when set (ear-first script from generation).
String programmeDescriptionTtsText(Program program) {
  if (program.coachRationaleSpoken?.trim().isNotEmpty == true) {
    return program.coachRationaleSpoken!;
  }
  if (program.coachRationale?.trim().isNotEmpty == true) {
    return program.coachRationale!;
  }
  return program.coachIntro?.trim() ?? program.name;
}

/// If the user is premium and programme description audio is missing, starts
/// generation (and workout intro generation when breakdowns exist). If a file
/// already exists locally or can be fetched from Storage, only refreshes notifier
/// state — no TTS call.
///
/// Call from programme preview (prefetch) so "Tell me about" usually finds audio
/// ready; safe to call again from About (idempotent generation).
Future<void> bootstrapProgrammeDescriptionAudio(WidgetRef ref, Program program) async {
  final premium = ref.read(premiumStatusProvider).valueOrNull == true;
  if (!premium) return;

  final description = programmeDescriptionTtsText(program);
  if (description.trim().isEmpty) return;

  final audioService = ref.read(programmeAudioServiceProvider);
  final existing = await audioService.getProgrammeAudioPath(program.id);
  if (existing != null) {
    await ref.read(programmeAudioNotifierProvider.notifier).refreshPath(program.id);
    return;
  }

  final notifier = ref.read(programmeAudioNotifierProvider.notifier);
  notifier.startGeneration(program.id, description);
  if (program.workoutBreakdowns != null && program.workoutBreakdowns!.trim().isNotEmpty) {
    notifier.startWorkoutIntroGenerations(program.id);
  }
}
