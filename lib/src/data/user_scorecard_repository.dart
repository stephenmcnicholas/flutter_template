import 'package:drift/drift.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:fytter/src/domain/user_scorecard.dart';

const String kLocalScorecardId = 'local';

/// Persists and loads the user scorecard (single row per device).
class UserScorecardRepository {
  UserScorecardRepository(this._db);

  final AppDatabase _db;

  Future<UserScorecard?> getScorecard() async {
    final entity = await (_db.select(_db.userScorecards)
          ..where((t) => t.id.equals(kLocalScorecardId)))
        .getSingleOrNull();
    if (entity == null) return null;
    return _entityToDomain(entity);
  }

  /// Returns the persisted scorecard or creates and stores defaults for [kLocalScorecardId].
  Future<UserScorecard> loadOrCreate() async {
    final existing = await getScorecard();
    if (existing != null) return existing;
    final fresh = UserScorecard(id: kLocalScorecardId);
    await upsertScorecard(fresh);
    return fresh;
  }

  Future<void> upsertScorecard(UserScorecard scorecard) async {
    final companion = UserScorecardsCompanion(
      id: Value(scorecard.id),
      consistency: Value(scorecard.consistency),
      progression: Value(scorecard.progression),
      endurance: Value(scorecard.endurance),
      variety: Value(scorecard.variety),
      fundamentals: Value(scorecard.fundamentals),
      selfAwareness: Value(scorecard.selfAwareness),
      curiosity: Value(scorecard.curiosity),
      reliability: Value(scorecard.reliability),
      adaptability: Value(scorecard.adaptability),
      independence: Value(scorecard.independence),
      computedLevel: Value(scorecard.computedLevel),
      lastUpdated: Value(scorecard.lastUpdated),
    );
    await _db.into(_db.userScorecards).insertOnConflictUpdate(companion);
  }

  UserScorecard _entityToDomain(UserScorecardEntity e) => UserScorecard(
        id: e.id,
        consistency: e.consistency,
        progression: e.progression,
        endurance: e.endurance,
        variety: e.variety,
        fundamentals: e.fundamentals,
        selfAwareness: e.selfAwareness,
        curiosity: e.curiosity,
        reliability: e.reliability,
        adaptability: e.adaptability,
        independence: e.independence,
        computedLevel: e.computedLevel,
        lastUpdated: e.lastUpdated,
      );
}
