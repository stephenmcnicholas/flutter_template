import 'package:fytter/src/domain/exercise_instructions.dart';
import 'package:fytter/src/services/audio/sentence_library.dart';

/// Resolves sentence IDs to display strings for instruction UI (full library, not tier-filtered).
class ExerciseInstructionText {
  ExerciseInstructionText._();

  static List<String> bulletsFromCue(ExerciseCueField field, SentenceLibrary lib) {
    return field.sentences.map(lib.getText).where((s) => s.trim().isNotEmpty).toList();
  }

  static String paragraphFromCue(ExerciseCueField? field, SentenceLibrary lib) {
    if (field == null) return '';
    return field.sentences.map(lib.getText).where((s) => s.trim().isNotEmpty).join(' ');
  }

  static String paragraphFromFixIds(List<String> fixIds, SentenceLibrary lib) {
    return fixIds.map(lib.getText).where((s) => s.trim().isNotEmpty).join(' ');
  }
}
