import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fytter/src/providers/unit_settings_provider.dart';
import 'package:fytter/src/utils/format_utils.dart';
import 'package:fytter/src/utils/shared_prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SharedPrefs.instance.resetForTests();
  });

  Future<void> waitForLoad(ProviderContainer container) async {
    for (var i = 0; i < 5; i++) {
      final state = container.read(unitSettingsProvider);
      if (!state.isLoading) return;
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  test('loads default units when no preference exists', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await waitForLoad(container);

    final state = container.read(unitSettingsProvider);
    expect(state.weightUnit, WeightUnit.kg);
    expect(state.distanceUnit, DistanceUnit.km);
    expect(state.isLoading, isFalse);
  });

  test('persists unit changes', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await waitForLoad(container);
    await container.read(unitSettingsProvider.notifier).setWeightUnit(WeightUnit.lb);
    await container.read(unitSettingsProvider.notifier).setDistanceUnit(DistanceUnit.mi);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('unitWeight'), 'lb');
    expect(prefs.getString('unitDistance'), 'mi');
  });

  test('restores persisted units on new container', () async {
    SharedPreferences.setMockInitialValues({
      'unitWeight': 'lb',
      'unitDistance': 'mi',
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await waitForLoad(container);

    final state = container.read(unitSettingsProvider);
    expect(state.weightUnit, WeightUnit.lb);
    expect(state.distanceUnit, DistanceUnit.mi);
    expect(state.isLoading, isFalse);
  });
}
