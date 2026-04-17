import 'dart:convert';

import 'package:crypto/crypto.dart';

/// SharedPreferences key for the SHA-256 of [assets/exercises/exercises.json].
/// When the bundled file changes, this no longer matches and we re-sync Drift.
const String kExercisesJsonAssetHashKey = 'exercises_json_sha256_v1';

/// Debug-only: set to true to force a full exercise re-sync on next [AppDatabase.seedInitialData].
const String kDebugForceReseedExercisesKey = 'debug_force_reseed_exercises_next_launch';

/// Deterministic hash of bundled exercise JSON for change detection.
String sha256HexOfUtf8(String content) {
  final digest = sha256.convert(utf8.encode(content));
  return digest.toString();
}
