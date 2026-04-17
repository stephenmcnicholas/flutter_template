import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/rule_engine/failed_set_adjuster.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
//import 'package:flutter/material.dart';

class LoggerSheetState {
  final bool visible;
  final bool minimized;
  final String? workoutName;
  final String? workoutId;
  final String? programId;
  final List<Exercise> initialExercises;
  final Map<String, List<Map<String, dynamic>>>? initialSetsByExercise;

  const LoggerSheetState({
    this.visible = false,
    this.minimized = false,
    this.workoutName,
    this.workoutId,
    this.programId,
    this.initialExercises = const [],
    this.initialSetsByExercise,
  });

  LoggerSheetState copyWith({
    bool? visible,
    bool? minimized,
    String? workoutName,
    String? workoutId,
    String? programId,
    List<Exercise>? initialExercises,
    Map<String, List<Map<String, dynamic>>>? initialSetsByExercise,
  }) {
    return LoggerSheetState(
      visible: visible ?? this.visible,
      minimized: minimized ?? this.minimized,
      workoutName: workoutName ?? this.workoutName,
      workoutId: workoutId ?? this.workoutId,
      programId: programId ?? this.programId,
      initialExercises: initialExercises ?? this.initialExercises,
      initialSetsByExercise: initialSetsByExercise ?? this.initialSetsByExercise,
    );
  }

  Map<String, dynamic> toJson() => {
    'visible': visible,
    'minimized': minimized,
    'workoutName': workoutName,
    'workoutId': workoutId,
    'programId': programId,
    'initialExercises': initialExercises.map((e) => e.toJson()).toList(),
    'initialSetsByExercise': initialSetsByExercise,
  };

  static LoggerSheetState fromJson(Map<String, dynamic> json) {
    return LoggerSheetState(
      visible: json['visible'] ?? false,
      minimized: json['minimized'] ?? false,
      workoutName: json['workoutName'],
      workoutId: json['workoutId'],
      programId: json['programId'] as String?,
      initialExercises: (json['initialExercises'] as List<dynamic>? ?? [])
          .map((e) => Exercise.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      initialSetsByExercise: (json['initialSetsByExercise'] as Map?)?.map((k, v) => MapEntry(
        k as String,
        (v as List).map((item) => Map<String, dynamic>.from(item)).toList(),
      )),
    );
  }
}

class LoggerSheetNotifier extends StateNotifier<LoggerSheetState> {
  static const _prefsKey = 'loggerSheetState';
  LoggerSheetNotifier() : super(const LoggerSheetState()) {
    _restoreState();
  }

  Future<void> _persistState(LoggerSheetState s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(s.toJson()));
  }

  Future<void> _restoreState() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefsKey);
    if (jsonStr != null) {
      try {
        final jsonMap = jsonDecode(jsonStr);
        state = LoggerSheetState.fromJson(jsonMap);
      } catch (_) {
        // Ignore errors and start fresh
        state = const LoggerSheetState();
      }
    }
  }

  void show({
    required String workoutName,
    String? workoutId,
    String? programId,
    List<Exercise> initialExercises = const [],
    Map<String, List<Map<String, dynamic>>>? initialSetsByExercise,
  }) {
    final newState = LoggerSheetState(
      visible: true,
      minimized: false,
      workoutName: workoutName,
      workoutId: workoutId,
      programId: programId,
      initialExercises: initialExercises,
      initialSetsByExercise: initialSetsByExercise,
    );
    state = newState;
    _persistState(newState);
  }

  void minimize() {
    if (state.visible) {
      final newState = state.copyWith(minimized: true);
      state = newState;
      _persistState(newState);
    }
  }

  void maximize() {
    if (state.visible) {
      final newState = state.copyWith(minimized: false);
      state = newState;
      _persistState(newState);
    }
  }

  void hide() {
    state = const LoggerSheetState();
    _persistState(state);
  }
}

final loggerSheetProvider = StateNotifierProvider<LoggerSheetNotifier, LoggerSheetState>((ref) {
  return LoggerSheetNotifier();
});

// Persistent logger session state for exercises and sets
class LoggerSessionState {
  final String workoutName;
  final String? workoutId;
  final List<Exercise> exercises;
  final Map<String, List<Map<String, dynamic>>> setsByExercise;
  final DateTime startedAt;
  /// Progress bar value in [0, 1]; never decreases when sets are added (bar never retreats).
  final double maxProgress;
  /// Maps exerciseId → supersetGroupId for exercises grouped into supersets.
  /// Used to stamp supersetGroupId onto new sets added during the session.
  final Map<String, String> supersetGroups;

  LoggerSessionState({
    required this.workoutName,
    this.workoutId,
    required this.exercises,
    required this.setsByExercise,
    required this.startedAt,
    this.maxProgress = 0.0,
    this.supersetGroups = const {},
  });

  LoggerSessionState copyWith({
    String? workoutName,
    String? workoutId,
    List<Exercise>? exercises,
    Map<String, List<Map<String, dynamic>>>? setsByExercise,
    DateTime? startedAt,
    double? maxProgress,
    Map<String, String>? supersetGroups,
  }) {
    return LoggerSessionState(
      workoutName: workoutName ?? this.workoutName,
      workoutId: workoutId ?? this.workoutId,
      exercises: exercises ?? this.exercises,
      setsByExercise: setsByExercise ?? this.setsByExercise,
      startedAt: startedAt ?? this.startedAt,
      maxProgress: maxProgress ?? this.maxProgress,
      supersetGroups: supersetGroups ?? this.supersetGroups,
    );
  }

  /// Completed sets count from [setsByExercise].
  static int completedSets(Map<String, List<Map<String, dynamic>>> setsByExercise) {
    int n = 0;
    for (final list in setsByExercise.values) {
      for (final set in list) {
        if (set['isComplete'] == true) n++;
      }
    }
    return n;
  }

  /// Total sets count from [setsByExercise].
  static int totalSets(Map<String, List<Map<String, dynamic>>> setsByExercise) {
    int n = 0;
    for (final list in setsByExercise.values) {
      n += list.length;
    }
    return n;
  }
}

class LoggerSessionNotifier extends StateNotifier<LoggerSessionState?> {
  LoggerSessionNotifier() : super(null);

  static double _progressFromSets(Map<String, List<Map<String, dynamic>>> setsByExercise) {
    final total = LoggerSessionState.totalSets(setsByExercise);
    return total > 0 ? LoggerSessionState.completedSets(setsByExercise) / total : 0.0;
  }

  void startSession(
    String workoutName,
    List<Exercise> initialExercises,
    Map<String, List<Map<String, dynamic>>>? initialSets, {
    String? workoutId,
  }) {
    final setsByExercise = initialSets != null
        ? _normalizeInitialSets(
            initialSets.map(
              (k, v) => MapEntry(
                k,
                v.map((raw) => Map<String, dynamic>.from(raw)).toList(),
              ),
            ),
          )
        : <String, List<Map<String, dynamic>>>{};

    // Pre-populate supersetGroups from any supersetGroupId already present on
    // the initial sets (e.g. when loading a saved template).
    final supersetGroups = <String, String>{};
    for (final entry in setsByExercise.entries) {
      final groupId = entry.value.firstOrNull?['supersetGroupId'] as String?;
      if (groupId != null) {
        supersetGroups[entry.key] = groupId;
      }
    }

    state = LoggerSessionState(
      workoutName: workoutName,
      workoutId: workoutId,
      exercises: List.of(initialExercises),
      setsByExercise: setsByExercise,
      startedAt: DateTime.now(),
      maxProgress: _progressFromSets(setsByExercise),
      supersetGroups: supersetGroups,
    );
  }

  void addExercise(Exercise ex) {
    if (state == null) return;
    if (state!.exercises.any((e) => e.id == ex.id)) return;
    final newSets = <String, List<Map<String, dynamic>>>{...state!.setsByExercise, ex.id: <Map<String, dynamic>>[]};
    final progress = _progressFromSets(newSets);
    final newMax = progress > state!.maxProgress ? progress : state!.maxProgress;
    state = state!.copyWith(
      exercises: [...state!.exercises, ex],
      setsByExercise: newSets,
      maxProgress: newMax,
    );
  }

  void removeExercise(String exerciseId) {
    if (state == null) return;
    final newExercises = state!.exercises.where((e) => e.id != exerciseId).toList();
    final newSets = Map<String, List<Map<String, dynamic>>>.from(state!.setsByExercise);
    newSets.remove(exerciseId);
    final newGroups = Map<String, String>.from(state!.supersetGroups);
    newGroups.remove(exerciseId);
    final progress = _progressFromSets(newSets);
    final newMax = progress > state!.maxProgress ? progress : state!.maxProgress;
    state = state!.copyWith(
      exercises: newExercises,
      setsByExercise: newSets,
      supersetGroups: newGroups,
      maxProgress: newMax,
    );
  }

  void addSet(String exerciseId, Map<String, dynamic> set) {
    if (state == null) return;
    // Stamp supersetGroupId onto the new set if this exercise is in a group.
    final groupId = state!.supersetGroups[exerciseId];
    final stamped = groupId != null ? {...set, 'supersetGroupId': groupId} : set;
    final sets = List<Map<String, dynamic>>.from(state!.setsByExercise[exerciseId] ?? []);
    sets.add(stamped);
    final newSets = {...state!.setsByExercise, exerciseId: sets};
    final progress = _progressFromSets(newSets);
    final newMax = progress > state!.maxProgress ? progress : state!.maxProgress;
    state = state!.copyWith(setsByExercise: newSets, maxProgress: newMax);
  }

  void updateSet(String exerciseId, int setIndex, Map<String, dynamic> set) {
    if (state == null) return;
    final sets = List<Map<String, dynamic>>.from(state!.setsByExercise[exerciseId] ?? []);
    if (setIndex < 0 || setIndex >= sets.length) return;
    sets[setIndex] = set;
    final newSets = {...state!.setsByExercise, exerciseId: sets};
    final progress = _progressFromSets(newSets);
    final newMax = progress > state!.maxProgress ? progress : state!.maxProgress;
    state = state!.copyWith(setsByExercise: newSets, maxProgress: newMax);
  }

  /// After a failed set at [completedSetIndex], scale weight on later incomplete sets (premium adaptation).
  void applyFailedSetLoadReduction(String exerciseId, int completedSetIndex) {
    if (state == null) return;
    final sets = List<Map<String, dynamic>>.from(state!.setsByExercise[exerciseId] ?? []);
    if (sets.isEmpty) return;
    final adjusted = FailedSetAdjuster.applyLoadReductionToRemaining(
      sets: sets,
      afterSetIndex: completedSetIndex,
    );
    final newSets = {...state!.setsByExercise, exerciseId: adjusted};
    state = state!.copyWith(setsByExercise: newSets);
  }

  void removeSet(String exerciseId, int setIndex) {
    if (state == null) return;
    final sets = List<Map<String, dynamic>>.from(state!.setsByExercise[exerciseId] ?? []);
    if (setIndex < 0 || setIndex >= sets.length) return;
    sets.removeAt(setIndex);
    final newSets = {...state!.setsByExercise, exerciseId: sets};
    final progress = _progressFromSets(newSets);
    final newMax = progress > state!.maxProgress ? progress : state!.maxProgress;
    state = state!.copyWith(setsByExercise: newSets, maxProgress: newMax);
  }

  /// Adds a single [exerciseId] to an existing superset [groupId], stamping
  /// [supersetGroupId] on all of its current sets, recording the mapping, and
  /// moving the exercise immediately after the last existing member of the group.
  void addToGroup(String exerciseId, String groupId) {
    if (state == null) return;

    // Update sets.
    final newSets = Map<String, List<Map<String, dynamic>>>.from(state!.setsByExercise);
    final current = List<Map<String, dynamic>>.from(newSets[exerciseId] ?? []);
    newSets[exerciseId] = current.map((s) => {...s, 'supersetGroupId': groupId}).toList();

    // Update supersetGroups map.
    final newGroups = Map<String, String>.from(state!.supersetGroups);
    newGroups[exerciseId] = groupId;

    // Reorder: move exerciseId to immediately after the last current group member.
    final exercises = List<Exercise>.from(state!.exercises);
    int lastGroupMemberIdx = -1;
    for (int i = 0; i < exercises.length; i++) {
      if (exercises[i].id != exerciseId && newGroups[exercises[i].id] == groupId) {
        lastGroupMemberIdx = i;
      }
    }
    if (lastGroupMemberIdx >= 0) {
      final currentIdx = exercises.indexWhere((e) => e.id == exerciseId);
      if (currentIdx >= 0 && currentIdx != lastGroupMemberIdx + 1) {
        final exToMove = exercises.removeAt(currentIdx);
        // After removal, adjust insertion index if we shifted the target left.
        final insertIdx = (currentIdx <= lastGroupMemberIdx
                ? lastGroupMemberIdx
                : lastGroupMemberIdx + 1)
            .clamp(0, exercises.length);
        exercises.insert(insertIdx, exToMove);
      }
    }

    state = state!.copyWith(
      exercises: exercises,
      setsByExercise: newSets,
      supersetGroups: newGroups,
    );
  }

  /// Groups [exerciseIds] (≥ 2) into a new superset, stamping [supersetGroupId]
  /// onto all their existing sets, storing the mapping so future sets get the
  /// same id via [addSet], and reordering the exercises list so the group
  /// members appear consecutively at the position of their earliest member.
  void groupExercisesAsSuperset(List<String> exerciseIds) {
    if (state == null || exerciseIds.length < 2) return;
    final groupId = const Uuid().v4();

    // Update sets.
    final newSets = Map<String, List<Map<String, dynamic>>>.from(state!.setsByExercise);
    for (final exId in exerciseIds) {
      final current = List<Map<String, dynamic>>.from(newSets[exId] ?? []);
      newSets[exId] = current.map((s) => {...s, 'supersetGroupId': groupId}).toList();
    }

    // Update supersetGroups map.
    final newGroups = Map<String, String>.from(state!.supersetGroups);
    for (final exId in exerciseIds) {
      newGroups[exId] = groupId;
    }

    // Reorder exercises: insert the group as a consecutive block at the position
    // of its first member (preserving the members' current relative order).
    final exerciseIdSet = exerciseIds.toSet();
    final currentExercises = state!.exercises;
    final groupMembers = currentExercises
        .where((e) => exerciseIdSet.contains(e.id))
        .toList(); // current display order preserved
    final newExercises = <Exercise>[];
    bool inserted = false;
    for (final ex in currentExercises) {
      if (exerciseIdSet.contains(ex.id)) {
        if (!inserted) {
          newExercises.addAll(groupMembers); // insert block at first member's slot
          inserted = true;
        }
        // Skip subsequent individual members — already added as part of block.
      } else {
        newExercises.add(ex);
      }
    }

    state = state!.copyWith(
      exercises: newExercises,
      setsByExercise: newSets,
      supersetGroups: newGroups,
    );
  }

  void reorderExercises(int oldIndex, int newIndex) {
    if (state == null) return;
    if (oldIndex < 0 || oldIndex >= state!.exercises.length) return;
    if (newIndex < 0 || newIndex >= state!.exercises.length) return;

    final newExercises = List<Exercise>.from(state!.exercises);
    int adjustedNew = newIndex;
    if (oldIndex < newIndex) {
      adjustedNew -= 1;
    }
    final exercise = newExercises.removeAt(oldIndex);
    newExercises.insert(adjustedNew, exercise);

    state = state!.copyWith(exercises: newExercises);
  }

  void clear() {
    state = null;
  }
}

final loggerSessionProvider = StateNotifierProvider<LoggerSessionNotifier, LoggerSessionState?>((ref) => LoggerSessionNotifier());

Map<String, List<Map<String, dynamic>>> _normalizeInitialSets(
  Map<String, List<Map<String, dynamic>>> raw,
) {
  return raw.map((key, list) => MapEntry(
        key,
        list.map((s) {
          final m = Map<String, dynamic>.from(s);
          m['targetReps'] ??= m['reps'];
          m['targetWeight'] ??= m['weight'];
          m['targetDistance'] ??= m['distance'];
          m['targetDuration'] ??= m['duration'];
          return m;
        }).toList(),
      ));
}
