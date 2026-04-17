import 'package:drift/drift.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:fytter/src/domain/session_check_in.dart';

/// Persists and queries session check-ins.
class SessionCheckInRepository {
  SessionCheckInRepository(this._db);

  final AppDatabase _db;

  Future<void> save(SessionCheckIn checkIn) async {
    final companion = SessionCheckInsCompanion(
      id: Value(checkIn.id),
      sessionId: Value(checkIn.sessionId),
      programmeId: Value(checkIn.programmeId),
      checkInType: Value(checkInTypeToStorage(checkIn.checkInType)),
      rating: Value(checkInRatingToStorage(checkIn.rating)),
      freeText: Value(checkIn.freeText),
      createdAt: Value(checkIn.createdAt),
    );
    await _db.into(_db.sessionCheckIns).insertOnConflictUpdate(companion);
  }

  Future<List<SessionCheckIn>> getBySession(String sessionId) async {
    final rows = await (_db.select(_db.sessionCheckIns)
          ..where((t) => t.sessionId.equals(sessionId)))
        .get();
    return rows.map(_entityToDomain).toList();
  }

  Future<List<SessionCheckIn>> getByProgramme(String programmeId) async {
    final rows = await (_db.select(_db.sessionCheckIns)
          ..where((t) => t.programmeId.equals(programmeId)))
        .get();
    return rows.map(_entityToDomain).toList();
  }

  Future<List<SessionCheckIn>> getRecent(int limit) async {
    final rows = await (_db.select(_db.sessionCheckIns)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
    return rows.map(_entityToDomain).toList();
  }

  SessionCheckIn _entityToDomain(SessionCheckInEntity e) => SessionCheckIn(
        id: e.id,
        sessionId: e.sessionId,
        programmeId: e.programmeId,
        checkInType: checkInTypeFromStorage(e.checkInType),
        rating: checkInRatingFromStorage(e.rating),
        freeText: e.freeText,
        createdAt: e.createdAt,
      );
}
