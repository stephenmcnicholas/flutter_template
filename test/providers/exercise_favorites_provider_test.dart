import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/exercise_favorites_provider.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  Future<void> waitForLoad(ProviderContainer container) async {
    for (var i = 0; i < 10; i++) {
      if (container.read(exerciseFavoritesProvider).hasValue) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  test('loads existing favorites from database', () async {
    final db = AppDatabase.test();
    await db.addExerciseFavorite('e1');

    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWith((_) => db)],
    );

    await waitForLoad(container);
    final state = container.read(exerciseFavoritesProvider);
    expect(state.value, contains('e1'));
  });

  test('toggleFavorite adds and removes favorites', () async {
    final db = AppDatabase.test();
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWith((_) => db)],
    );
    final notifier = container.read(exerciseFavoritesProvider.notifier);

    await waitForLoad(container);
    await notifier.toggleFavorite('e2');
    expect(container.read(exerciseFavoritesProvider).value, contains('e2'));

    await notifier.toggleFavorite('e2');
    expect(container.read(exerciseFavoritesProvider).value, isNot(contains('e2')));
  });
}
