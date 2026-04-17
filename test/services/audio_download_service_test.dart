import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/services/audio/audio_download_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFirebaseStorage extends Mock implements FirebaseStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('isTypeAMarkedDownloaded is false initially', () async {
    SharedPreferences.setMockInitialValues({});
    final svc = AudioDownloadService(
      storage: MockFirebaseStorage(),
      assetBundle: rootBundle,
    );
    expect(await svc.isTypeAMarkedDownloaded(), isFalse);
  });

  test('triggerTypeADownloadOnPremiumActivation no-ops without Firebase', () async {
    SharedPreferences.setMockInitialValues({});
    final svc = AudioDownloadService(
      storage: MockFirebaseStorage(),
      assetBundle: rootBundle,
    );
    await svc.triggerTypeADownloadOnPremiumActivation();
  });
}
