import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/utils/haptic_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ALL HapticFeedback methods send 'HapticFeedback.vibrate' as the method
  // name and the impact type as the argument. We intercept at the binary
  // messenger level to capture the decoded MethodCall.
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('SystemHapticsService — enabled', () {
    late SystemHapticsService service;

    setUp(() => service = const SystemHapticsService(enabled: true));

    test('light() sends HapticFeedback.vibrate with lightImpact argument', () async {
      service.light();
      await Future<void>.value();
      expect(
        calls.any(
          (c) =>
              c.method == 'HapticFeedback.vibrate' &&
              c.arguments == 'HapticFeedbackType.lightImpact',
        ),
        isTrue,
        reason: 'Expected lightImpact haptic call, got: $calls',
      );
    });

    test('medium() sends HapticFeedback.vibrate with mediumImpact argument', () async {
      service.medium();
      await Future<void>.value();
      expect(
        calls.any(
          (c) =>
              c.method == 'HapticFeedback.vibrate' &&
              c.arguments == 'HapticFeedbackType.mediumImpact',
        ),
        isTrue,
        reason: 'Expected mediumImpact haptic call, got: $calls',
      );
    });

    test('heavy() sends HapticFeedback.vibrate with heavyImpact argument', () async {
      service.heavy();
      await Future<void>.value();
      expect(
        calls.any(
          (c) =>
              c.method == 'HapticFeedback.vibrate' &&
              c.arguments == 'HapticFeedbackType.heavyImpact',
        ),
        isTrue,
        reason: 'Expected heavyImpact haptic call, got: $calls',
      );
    });
  });

  group('SystemHapticsService — disabled', () {
    late SystemHapticsService service;

    setUp(() => service = const SystemHapticsService(enabled: false));

    test('light() fires no haptic when disabled', () async {
      service.light();
      await Future<void>.value();
      expect(
        calls.where((c) => c.method == 'HapticFeedback.vibrate'),
        isEmpty,
      );
    });

    test('medium() fires no haptic when disabled', () async {
      service.medium();
      await Future<void>.value();
      expect(
        calls.where((c) => c.method == 'HapticFeedback.vibrate'),
        isEmpty,
      );
    });

    test('heavy() fires no haptic when disabled', () async {
      service.heavy();
      await Future<void>.value();
      expect(
        calls.where((c) => c.method == 'HapticFeedback.vibrate'),
        isEmpty,
      );
    });
  });
}
