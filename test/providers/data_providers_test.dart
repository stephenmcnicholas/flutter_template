import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/workout_session_provider.dart';

void main() {
  test('data providers are available', () {
    final container = ProviderContainer();
    expect(container.read(appDatabaseProvider), isNotNull);
    expect(container.read(exerciseRepositoryProvider), isNotNull);
    expect(container.read(workoutRepositoryProvider), isNotNull);
    expect(container.read(workoutEntryRepositoryProvider), isNotNull);
    expect(container.read(workoutSessionRepositoryProvider), isNotNull);
    expect(container.read(programRepositoryProvider), isNotNull);
  });
} 