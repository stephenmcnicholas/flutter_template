import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/utils/format_utils.dart';
import 'package:fytter/src/utils/shared_prefs.dart';

class UnitSettingsState {
  final WeightUnit weightUnit;
  final DistanceUnit distanceUnit;
  final bool isLoading;

  const UnitSettingsState({
    required this.weightUnit,
    required this.distanceUnit,
    this.isLoading = false,
  });

  UnitSettingsState copyWith({
    WeightUnit? weightUnit,
    DistanceUnit? distanceUnit,
    bool? isLoading,
  }) {
    return UnitSettingsState(
      weightUnit: weightUnit ?? this.weightUnit,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class UnitSettingsNotifier extends StateNotifier<UnitSettingsState> {
  static const _prefsKeyWeightUnit = 'unitWeight';
  static const _prefsKeyDistanceUnit = 'unitDistance';

  UnitSettingsNotifier()
      : super(const UnitSettingsState(
          weightUnit: WeightUnit.kg,
          distanceUnit: DistanceUnit.km,
          isLoading: true,
        )) {
    _load();
  }

  Future<void> _load() async {
    final prefs = SharedPrefs.instance;
    final weightValue = await prefs.getString(_prefsKeyWeightUnit);
    final distanceValue = await prefs.getString(_prefsKeyDistanceUnit);
    final weightUnit = WeightUnit.values.firstWhere(
      (unit) => unit.name == weightValue,
      orElse: () => WeightUnit.kg,
    );
    final distanceUnit = DistanceUnit.values.firstWhere(
      (unit) => unit.name == distanceValue,
      orElse: () => DistanceUnit.km,
    );
    state = state.copyWith(
      weightUnit: weightUnit,
      distanceUnit: distanceUnit,
      isLoading: false,
    );
  }

  Future<void> setWeightUnit(WeightUnit unit) async {
    if (unit == state.weightUnit && !state.isLoading) return;
    state = state.copyWith(weightUnit: unit, isLoading: false);
    await SharedPrefs.instance.setString(_prefsKeyWeightUnit, unit.name);
  }

  Future<void> setDistanceUnit(DistanceUnit unit) async {
    if (unit == state.distanceUnit && !state.isLoading) return;
    state = state.copyWith(distanceUnit: unit, isLoading: false);
    await SharedPrefs.instance.setString(_prefsKeyDistanceUnit, unit.name);
  }
}

final unitSettingsProvider =
    StateNotifierProvider<UnitSettingsNotifier, UnitSettingsState>((ref) {
  return UnitSettingsNotifier();
});
