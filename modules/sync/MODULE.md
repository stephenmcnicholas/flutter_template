# Module: Offline-First Cloud Sync

**What it does:** Bidirectional sync between local Drift SQLite storage and Firestore. Data is written locally first (offline-safe), queued for push to Firestore, and pulled from Firestore on launch. Users get a seamless experience with or without connectivity, and their data is available on any device after sign-in.

**Architecture:**

```
Local write → Drift table → SyncQueue entry → SyncService → Firestore
                                                                 ↓
UI ← provider invalidation ← PullService ← Firestore (on launch)
```

**Pattern components:**

- `FirestorePaths` — typed Firestore path constants. No logic. One class, all paths. Prevents string typos across the codebase.
- `SyncQueue` — a Drift table. Stores entity type + ID + timestamp for every local write that needs to be pushed. Used when offline; drained when connectivity resumes.
- `SyncMetadataService` — tracks the last successful pull timestamp in SharedPreferences. Prevents redundant pulls.
- `SyncService` (push) — called after every local write. Pushes entity to Firestore, writes a tombstone on delete. If offline, adds to SyncQueue for later retry.
- `PullService` (pull) — called once on launch after authentication. Pulls all user data changed since the last pull. Returns the sync timestamp so providers can be invalidated.
- `lastBackedUpProvider` — a `StateProvider<DateTime?>` showing when data was last synced. Displayed in Settings as "Last backed up · X minutes ago".

**Pull-on-launch pattern (in app widget initState):**

```dart
WidgetsBinding.instance.addPostFrameCallback((_) async {
  final user = ref.read(authUserProvider).valueOrNull;
  if (user == null) return;
  final pullService = ref.read(pullServiceProvider);
  final syncedAt = await pullService.pullOnLaunch(user.uid);
  if (syncedAt != null && mounted) {
    ref.read(lastBackedUpProvider.notifier).state = syncedAt;
    // Invalidate all data providers so the UI reflects restored data.
    // Replace with your app's providers:
    ref.invalidate(yourDataProvider);
  }
});
```

**Conflict resolution:** Last-write-wins on `updatedAt` timestamp. Each entity must carry an `updatedAt` field updated on every local write.

**First sign-in migration:** `SyncService.migrateAllLocalToFirestore(uid)` — pushes all existing local data to Firestore when a user signs in for the first time. Run once, gated on a flag in `UserProfile`.

**Files to create (app-specific implementations):**
- `lib/src/data/firestore_paths.dart` — path constants
- `lib/src/data/sync_queue_table.dart` — Drift table definition + add to `app_database.dart`
- `lib/src/services/sync_metadata_service.dart`
- `lib/src/services/sync_service.dart` — push-on-write, one method per entity type
- `lib/src/services/pull_service.dart` — pull-on-launch
- `lib/src/providers/sync_providers.dart` — `syncServiceProvider`, `pullServiceProvider`, `lastBackedUpProvider`

**pubspec.yaml dependencies:** `shared_preferences` (already present in template)

**Firestore dependencies:** `cloud_firestore` (already present in template)

**Dependencies:** Auth module (uid required), Database module (Drift tables for SyncQueue)

**Reference implementation:** See `/Users/stephenmcnicholas/Developer/flutter_projects/fytter` — `lib/src/services/sync_service.dart`, `pull_service.dart`, `sync_metadata_service.dart`, `lib/src/data/firestore_paths.dart`, `lib/src/providers/sync_providers.dart`.

**To include this module in a new project:**
1. Decide upfront — sync architecture affects your Drift table design (every entity needs `updatedAt`, `syncedAt`, optional `deletedAt` for tombstones)
2. Create `FirestorePaths` with your app's collection names
3. Add `SyncQueue` Drift table to `app_database.dart`, run build_runner
4. Implement `SyncService` with one push method per entity type
5. Implement `PullService` for each collection
6. Add providers to `sync_providers.dart`
7. Wire pull-on-launch into the app widget's `initState`
8. Add `migrateAllLocalToFirestore` call to the sign-in flow (first sign-in only)
9. Add "Last backed up" display to the Settings screen

**To remove this module (if not needed):**
1. Do not create any of the files listed above
2. Remove the pull-on-launch pattern from the app widget
3. `shared_preferences` can stay (used by notification settings)

**Note:** Decide whether you need this module before designing your Drift tables. Adding sync to an existing schema is harder than designing for it from the start.
