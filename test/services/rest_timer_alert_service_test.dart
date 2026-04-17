import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/services/rest_timer_alert_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SystemRestTimerAlertService', () {
    late SystemRestTimerAlertService service;

    setUp(() {
      service = SystemRestTimerAlertService();
    });

    test('notifyComplete with both flags completes without error', () async {
      await service.notifyComplete(playHaptics: true, playSound: true);
    });

    test('notifyComplete with haptics only completes', () async {
      await service.notifyComplete(playHaptics: true, playSound: false);
    });

    test('notifyComplete with sound only completes', () async {
      await service.notifyComplete(playHaptics: false, playSound: true);
    });

    test('notifyComplete with both false completes', () async {
      await service.notifyComplete(playHaptics: false, playSound: false);
    });
  });
}
