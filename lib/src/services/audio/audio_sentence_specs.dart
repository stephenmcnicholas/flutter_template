import 'package:fytter/src/domain/exercise_instructions.dart';
import 'package:fytter/src/services/audio/audio_service.dart';
import 'package:fytter/src/services/audio/coaching_audio_tier.dart';
import 'package:fytter/src/services/audio/sentence_library.dart';

/// Converts [ExerciseCueField] + tier into clip specs (mid/final + fallback).
List<AudioClipSpec> audioSpecsForCueField({
  required ExerciseCueField field,
  required CoachingAudioTier tier,
  required SentenceLibrary sentences,
}) {
  final tierName = coachingTierStorageName(tier);
  final indices = field.tiers[tierName];
  if (indices == null) return [];
  final out = <AudioClipSpec>[];
  for (var i = 0; i < indices.length; i++) {
    final idx = indices[i];
    if (idx < 0 || idx >= field.sentences.length) continue;
    final sid = field.sentences[idx];
    final isLast = i == indices.length - 1;
    final wanted = isLast ? 'final' : 'mid';
    final variant = sentences.pickVariant(sid, wanted);
    out.add(AudioClipSpec.sentence(sentenceId: sid, variant: variant));
  }
  return out;
}

ExerciseFixTier? _fixTier(ExerciseCommonFix fix, String tierName) => fix.tiers[tierName];

/// On-demand common fix: fix lines only (last = final). The issue label is
/// already shown in the coaching panel UI, so it is never spoken.
List<AudioClipSpec> audioSpecsForCommonFix({
  required ExerciseCommonFix fix,
  required CoachingAudioTier tier,
  required SentenceLibrary sentences,
}) {
  final tierName = coachingTierStorageName(tier);
  final t = _fixTier(fix, tierName);
  if (t == null) return [];
  final out = <AudioClipSpec>[];
  final fixIndices = t.fix;
  for (var i = 0; i < fixIndices.length; i++) {
    final idx = fixIndices[i];
    if (idx < 0 || idx >= fix.fix.length) continue;
    final sid = fix.fix[idx];
    final isLast = i == fixIndices.length - 1;
    final wanted = isLast ? 'final' : 'mid';
    out.add(AudioClipSpec.sentence(sentenceId: sid, variant: sentences.pickVariant(sid, wanted)));
  }
  return out;
}
