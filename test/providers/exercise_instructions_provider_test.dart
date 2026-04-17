import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/providers/exercise_instructions_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const cue = '''
{
  "sentences": ["s1"],
  "tiers": {"beginner": [0], "intermediate": [0], "advanced": [0]}
}
''';

  var mockJson = '';

  setUp(() {
    mockJson = '''
[
  {
    "id": "e1",
    "instructions": {
      "setup": $cue,
      "movement": $cue,
      "commonFixes": [{
        "issue": "s_issue",
        "fix": ["s_fix"],
        "tiers": {
          "beginner": {"issue": true, "fix": [0]},
          "intermediate": {"issue": true, "fix": [0]},
          "advanced": {"issue": true, "fix": [0]}
        }
      }],
      "makeItEasier": [{"name": "Alt", "description": "Alt desc", "exerciseId": "alt"}],
      "levelUp": {"description": "Level up", "exerciseId": "lvl"},
      "breathingCue": $cue,
      "safetyNote": "Safe"
    }
  },
  {
    "id": "e2"
  }
]
''';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
      'flutter/assets',
      (message) async {
        final key = utf8.decode(message!.buffer.asUint8List());
        if (key == 'assets/exercises/exercises.json') {
          final bytes = utf8.encode(mockJson);
          return ByteData.view(Uint8List.fromList(bytes).buffer);
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  test('exerciseInstructionsMapProvider maps instructions by id', () async {
    final container = ProviderContainer();
    final map = await container.read(exerciseInstructionsMapProvider.future);
    expect(map.containsKey('e1'), isTrue);
    expect(map.containsKey('e2'), isFalse);
  });

  test('exerciseInstructionsProvider returns instruction details', () async {
    final container = ProviderContainer();
    final instructions =
        await container.read(exerciseInstructionsProvider('e1').future);
    expect(instructions, isNotNull);
    expect(instructions!.setup.sentences, ['s1']);
    expect(instructions.movement.sentences, ['s1']);
    expect(instructions.commonFixes.first.issue, 's_issue');
    expect(instructions.makeItEasier.first.name, 'Alt');
    expect(instructions.levelUp?.exerciseId, 'lvl');
    expect(instructions.breathingCue?.sentences, ['s1']);
    expect(instructions.safetyNote, 'Safe');
  });
}
