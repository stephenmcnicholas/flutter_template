import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/program_repository.dart';
import 'package:fytter/src/providers/programme_audio_provider.dart';
import 'package:fytter/src/services/programme_audio_service.dart';
import 'package:mocktail/mocktail.dart';

class MockProgramRepository extends Mock implements ProgramRepository {}

class MockProgrammeAudioService extends Mock implements ProgrammeAudioService {}

void main() {
  late MockProgrammeAudioService audio;
  late MockProgramRepository repo;
  late ProgrammeAudioNotifier notifier;

  setUp(() {
    audio = MockProgrammeAudioService();
    repo = MockProgramRepository();
    notifier = ProgrammeAudioNotifier(audio, repo);
  });

  test('removeProgram clears state', () {
    notifier.state = {
      'p1': const ProgrammeAudioStatus(path: '/x'),
    };
    notifier.removeProgram('p1');
    expect(notifier.state.containsKey('p1'), isFalse);
  });

  test('removeProgram no-op when id missing', () {
    notifier.state = {};
    notifier.removeProgram('missing');
    expect(notifier.state, isEmpty);
  });

  test('refreshPath no-op when no state and no path', () async {
    when(() => audio.getProgrammeAudioPath('p1')).thenAnswer((_) async => null);
    await notifier.refreshPath('p1');
    expect(notifier.state, isEmpty);
  });
}
