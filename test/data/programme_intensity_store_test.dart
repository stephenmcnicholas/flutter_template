import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/data/programme_intensity_store.dart';
import 'package:fytter/src/domain/session_check_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('ProgrammeIntensityStore.targetScaleForMidRating', () {
    test('maps too easy / hard / about right', () {
      expect(
        ProgrammeIntensityStore.targetScaleForMidRating(CheckInRating.tooEasy),
        closeTo(1.05, 0.001),
      );
      expect(
        ProgrammeIntensityStore.targetScaleForMidRating(CheckInRating.tooHard),
        closeTo(0.92, 0.001),
      );
      expect(
        ProgrammeIntensityStore.targetScaleForMidRating(CheckInRating.aboutRight),
        1.0,
      );
    });
  });

  group('ProgrammeIntensityStore load / set scale', () {
    test('null or empty program id yields 1.0', () async {
      expect(await ProgrammeIntensityStore.loadScaleForProgram(null), 1.0);
      expect(await ProgrammeIntensityStore.loadScaleForProgram(''), 1.0);
    });

    test('setLoadScaleForProgram clamps to 0.75–1.25', () async {
      await ProgrammeIntensityStore.setLoadScaleForProgram('p1', 99.0);
      expect(await ProgrammeIntensityStore.loadScaleForProgram('p1'), 1.25);
      await ProgrammeIntensityStore.setLoadScaleForProgram('p1', 0.1);
      expect(await ProgrammeIntensityStore.loadScaleForProgram('p1'), 0.75);
    });

    test('applyMidProgrammeRating sets scale from rating', () async {
      await ProgrammeIntensityStore.applyMidProgrammeRating('p2', CheckInRating.tooEasy);
      expect(await ProgrammeIntensityStore.loadScaleForProgram('p2'), closeTo(1.05, 0.001));
    });

    test('applyMidProgrammeRating tooHard lowers scale', () async {
      await ProgrammeIntensityStore.applyMidProgrammeRating('p3', CheckInRating.tooHard);
      expect(await ProgrammeIntensityStore.loadScaleForProgram('p3'), closeTo(0.92, 0.001));
    });
  });
}
