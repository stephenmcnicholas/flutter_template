import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('getFCMToken returns null when Firebase not initialized', () async {
    final token = await getFCMToken();
    expect(token, isNull);
  });

  test('requestNotificationPermission false without Firebase', () async {
    final ok = await requestNotificationPermission();
    expect(ok, isFalse);
  });
}
