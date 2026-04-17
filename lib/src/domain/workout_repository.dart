import 'workout.dart';

abstract class WorkoutRepository {
  Future<List<Workout>> findAll(); 
  Future<Workout>    findById(String id);
  Future<void>      save(Workout workout);
  Future<void>      delete(String id);
}