import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/services/programme_audio_service.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseStorage extends Mock implements FirebaseStorage {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProgrammeAudioService svc;

  setUp(() {
    svc = ProgrammeAudioService(
      storage: MockFirebaseStorage(),
      auth: MockFirebaseAuth(),
    );
  });

  test('generateAndSave returns null for empty description', () async {
    expect(await svc.generateAndSave('p1', '   '), isNull);
  });

  test('generateAndSaveWorkoutIntro returns null when workoutId empty', () async {
    expect(await svc.generateAndSaveWorkoutIntro('', 'Brief'), isNull);
  });

  test('deleteWorkoutIntro no-op for empty id', () async {
    await svc.deleteWorkoutIntro('');
  });

  test('deleteAllWorkoutIntrosForProgramme with empty ids completes', () async {
    await svc.deleteAllWorkoutIntrosForProgramme([]);
  });
}
