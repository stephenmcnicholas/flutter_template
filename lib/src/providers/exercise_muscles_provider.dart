import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final exerciseMusclesMapProvider =
    FutureProvider<Map<String, List<String>>>((ref) async {
  final jsonString = await rootBundle.loadString('assets/exercises/exercises.json');
  final list = json.decode(jsonString) as List<dynamic>;
  final map = <String, List<String>>{};

  for (final rawItem in list) {
    if (rawItem is! Map<String, dynamic>) continue;
    final id = rawItem['id'] as String?;
    if (id == null) continue;
    final primary = (rawItem['primaryMuscles'] as List<dynamic>? ?? [])
        .map((item) => item.toString())
        .toList();
    final secondary = (rawItem['secondaryMuscles'] as List<dynamic>? ?? [])
        .map((item) => item.toString())
        .toList();
    map[id] = [...primary, ...secondary];
  }

  return map;
});

final exercisePrimaryMusclesProvider =
    FutureProvider.family<List<String>, String>((ref, id) async {
  final jsonString = await rootBundle.loadString('assets/exercises/exercises.json');
  final list = json.decode(jsonString) as List<dynamic>;
  for (final rawItem in list) {
    if (rawItem is! Map<String, dynamic>) continue;
    if (rawItem['id'] != id) continue;
    return (rawItem['primaryMuscles'] as List<dynamic>? ?? [])
        .map((item) => item.toString())
        .toList();
  }
  return const [];
});

final exerciseSecondaryMusclesProvider =
    FutureProvider.family<List<String>, String>((ref, id) async {
  final jsonString = await rootBundle.loadString('assets/exercises/exercises.json');
  final list = json.decode(jsonString) as List<dynamic>;
  for (final rawItem in list) {
    if (rawItem is! Map<String, dynamic>) continue;
    if (rawItem['id'] != id) continue;
    return (rawItem['secondaryMuscles'] as List<dynamic>? ?? [])
        .map((item) => item.toString())
        .toList();
  }
  return const [];
});
