import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/providers/exercise_muscles_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const mockJson = '''
[
  {
    "id": "e1",
    "primaryMuscles": ["Chest"],
    "secondaryMuscles": ["Triceps", "Core"]
  },
  {
    "id": "e2",
    "primaryMuscles": ["Back"],
    "secondaryMuscles": []
  }
]
''';

  setUp(() {
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

  test('exerciseMusclesMapProvider merges primary and secondary muscles', () async {
    final container = ProviderContainer();
    final map = await container.read(exerciseMusclesMapProvider.future);
    expect(map['e1'], containsAll(['Chest', 'Triceps', 'Core']));
    expect(map['e2'], containsAll(['Back']));
  });

  test('exercisePrimaryMusclesProvider returns primary muscles', () async {
    final container = ProviderContainer();
    final muscles =
        await container.read(exercisePrimaryMusclesProvider('e1').future);
    expect(muscles, ['Chest']);
  });

  test('exerciseSecondaryMusclesProvider returns secondary muscles', () async {
    final container = ProviderContainer();
    final muscles =
        await container.read(exerciseSecondaryMusclesProvider('e1').future);
    expect(muscles, ['Triceps', 'Core']);
  });
}
