import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:fytter/src/providers/data_providers.dart';

class ExerciseFavoritesNotifier extends StateNotifier<AsyncValue<Set<String>>> {
  final AppDatabase _db;

  ExerciseFavoritesNotifier(this._db) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await _db.getAllExerciseFavorites();
      state = AsyncValue.data(rows.map((e) => e.exerciseId).toSet());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleFavorite(String exerciseId) async {
    final current = state.value ?? <String>{};
    final isFavorite = current.contains(exerciseId);
    if (isFavorite) {
      await _db.removeExerciseFavorite(exerciseId);
      state = AsyncValue.data({...current}..remove(exerciseId));
    } else {
      await _db.addExerciseFavorite(exerciseId);
      state = AsyncValue.data({...current, exerciseId});
    }
  }
}

final exerciseFavoritesProvider =
    StateNotifierProvider<ExerciseFavoritesNotifier, AsyncValue<Set<String>>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ExerciseFavoritesNotifier(db);
});
