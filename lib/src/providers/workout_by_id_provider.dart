// lib/src/providers/workout_by_id_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/domain/workout.dart';

/// A provider that fetches a single Workout by its ID for the HistoryDetailScreen.
final workoutByIdProvider = FutureProvider.family<Workout, String>(
  (ref, workoutId) async {
    // Read the WorkoutRepository from our centralized data providers
    final workoutRepo = ref.read(workoutRepositoryProvider);
    // Fetch and return the workout with the given ID
    return workoutRepo.findById(workoutId);
  },
);