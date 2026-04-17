import 'package:fytter/src/domain/program.dart';

/// Defines CRUD operations for [Program] templates.
abstract class ProgramRepository {
  /// Returns all saved programs.
  Future<List<Program>> findAll();

  /// Finds a single program by its [id], or throws if not found.
  Future<Program> findById(String id);

  /// Adds a new program or updates an existing one.
  Future<void> save(Program program);

  /// Deletes the program with the given [id].
  Future<void> delete(String id);
}