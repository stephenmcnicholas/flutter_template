import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fytter/src/providers/profile_provider.dart';
import 'package:fytter/src/utils/shared_prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SharedPrefs.instance.resetForTests();
  });

  Future<void> waitForLoad(ProviderContainer container) async {
    for (var i = 0; i < 5; i++) {
      final state = container.read(profileProvider);
      if (!state.isLoading) return;
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  test('loads default profile when no preference exists', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await waitForLoad(container);

    final state = container.read(profileProvider);
    expect(state.displayName, '');
    expect(state.email, '');
    expect(state.isLoading, isFalse);
  });

  test('persists profile changes', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await waitForLoad(container);
    await container.read(profileProvider.notifier).setProfile(
          displayName: 'Sam Mc',
          email: 'sam@example.com',
        );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('profileDisplayName'), 'Sam Mc');
    expect(prefs.getString('profileEmail'), 'sam@example.com');
  });

  test('restores persisted profile on new container', () async {
    SharedPreferences.setMockInitialValues({
      'profileDisplayName': 'Alex',
      'profileEmail': 'alex@example.com',
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await waitForLoad(container);

    final state = container.read(profileProvider);
    expect(state.displayName, 'Alex');
    expect(state.email, 'alex@example.com');
    expect(state.isLoading, isFalse);
  });
}
