import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/domain/exercise_instructions.dart';

final exerciseInstructionsMapProvider =
    FutureProvider<Map<String, ExerciseInstructions>>((ref) async {
  final jsonString = await rootBundle.loadString('assets/exercises/exercises.json');
  final list = json.decode(jsonString) as List<dynamic>;
  final map = <String, ExerciseInstructions>{};

  for (final rawItem in list) {
    if (rawItem is! Map<String, dynamic>) continue;
    final id = rawItem['id'] as String?;
    final instructions = rawItem['instructions'];
    if (id == null || instructions is! Map<String, dynamic>) continue;
    try {
      map[id] = ExerciseInstructions.fromJson(instructions);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[exerciseInstructionsMapProvider] skip $id: $e');
        debugPrint('$st');
      }
    }
  }

  return map;
});

final exerciseInstructionsProvider =
    FutureProvider.family<ExerciseInstructions?, String>((ref, id) async {
  final map = await ref.watch(exerciseInstructionsMapProvider.future);
  return map[id];
});
