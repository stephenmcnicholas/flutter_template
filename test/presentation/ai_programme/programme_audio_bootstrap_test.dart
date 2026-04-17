import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/program.dart';
import 'package:fytter/src/presentation/ai_programme/programme_audio_bootstrap.dart';

void main() {
  group('programmeDescriptionTtsText', () {
    test('prefers coachRationaleSpoken when non-empty', () {
      final p = Program(
        id: '1',
        name: 'N',
        coachRationale: 'Long written copy for the screen.',
        coachRationaleSpoken: 'Short voice script.',
      );
      expect(programmeDescriptionTtsText(p), 'Short voice script.');
    });

    test('falls back to coachRationale when spoken missing', () {
      final p = Program(
        id: '1',
        name: 'N',
        coachRationale: 'Written only.',
      );
      expect(programmeDescriptionTtsText(p), 'Written only.');
    });

    test('falls back to coachIntro then name', () {
      expect(
        programmeDescriptionTtsText(Program(id: '1', name: 'My Plan', coachIntro: 'Hi there')),
        'Hi there',
      );
      expect(
        programmeDescriptionTtsText(const Program(id: '1', name: 'Solo')),
        'Solo',
      );
    });

    test('ignores whitespace-only spoken', () {
      final p = Program(
        id: '1',
        name: 'N',
        coachRationaleSpoken: '   ',
        coachRationale: 'Real text',
      );
      expect(programmeDescriptionTtsText(p), 'Real text');
    });
  });
}
