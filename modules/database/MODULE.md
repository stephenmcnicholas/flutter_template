# Module: Local Database

**What it does:** Drift (SQLite ORM) providing offline-first local data persistence with typed queries and migration support. Repository pattern abstracts storage behind domain interfaces.

**Files:**
- `lib/src/data/app_database.dart` — Drift database definition and migrations
- `lib/src/data/app_database.g.dart` — generated file, do not edit
- `pubspec.yaml` dependencies: `drift`, `drift_flutter`, `sqlite3_flutter_libs`, `path_provider`, `path`
- `pubspec.yaml` dev_dependencies: `drift_dev`, `build_runner`

**Dependencies:** None (standalone)

**To remove this module:**
1. Delete `lib/src/data/app_database.dart` and `app_database.g.dart`
2. Remove from `pubspec.yaml`: `drift`, `drift_flutter`, `sqlite3_flutter_libs`
3. Remove from `pubspec.yaml` dev: `drift_dev`, `build_runner`
4. Remove database provider from `lib/src/providers/data_providers.dart`
5. Remove repository implementations that use the database

**Note:** If removing local database, ensure all data access goes through Firestore directly. Consider if offline support is still required.
