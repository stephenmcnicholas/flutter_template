# Module: Local Database

**What it does:** Drift (SQLite ORM) providing offline-first local data persistence with typed queries and migration support. Repository pattern abstracts storage behind domain interfaces.

**Files:**
- `lib/src/data/app_database.dart` — Drift database definition and migrations
- `lib/src/data/app_database.g.dart` — generated file, do not edit
- `lib/src/data/app_database_connection.dart` — platform-agnostic connection interface
- `lib/src/data/app_database_connection_io.dart` — native (mobile/desktop) connection
- `lib/src/data/app_database_connection_web.dart` — web connection
- `lib/src/data/app_database_connection_stub.dart` — stub for unsupported platforms
- `pubspec.yaml` dependencies: `drift`, `drift_flutter`, `sqlite3_flutter_libs`, `path_provider`, `path`
- `pubspec.yaml` dev_dependencies: `drift_dev`, `build_runner`

**Dependencies:** None (standalone)

**To remove this module:**
1. Delete all `app_database*.dart` files in `lib/src/data/`
2. Remove from `pubspec.yaml`: `drift`, `drift_flutter`, `sqlite3_flutter_libs`
3. Remove from `pubspec.yaml` dev: `drift_dev`, `build_runner`
4. Remove database provider from `lib/src/providers/data_providers.dart`
5. Remove repository implementations that use the database

**Note:** If removing local database, ensure all data access goes through Firestore directly. Consider if offline support is still required.

## GDPR data export (pre-launch requirement for EU apps)

GDPR Article 20 (right to data portability) requires that users can export their data on request.

**Implementation pattern:**
1. Add a "Export my data" action in Settings
2. Query all user-owned Drift tables
3. Serialize the results to JSON
4. Share via the system share sheet (`Share.share(jsonString)` from the `share_plus` package)

The implementation is app-specific (which tables to include), but the pattern is generic. Plan for this when designing your Drift schema — make sure every table has a clear user ownership relationship.
