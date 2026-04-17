import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:fytter/src/data/program_repository_impl.dart';
import 'package:fytter/src/data/programme_generation_service.dart';
import 'package:fytter/src/data/workout_repository_impl.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/programme_generation_provider.dart';

class _LimitReachedService extends ProgrammeGenerationService {
  _LimitReachedService(AppDatabase db)
      : super(
          programRepository: ProgramRepositoryImpl(db),
          workoutRepository: WorkoutRepositoryImpl(db),
        );

  @override
  Future<ProgrammeGenerationResult> generateAndSave(
      ProgrammeGenerationRequest _) async {
    throw const ProgrammeGenerationLimitException();
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.test();
  });

  tearDown(() async {
    await db.close();
  });

  test('generate sets LimitReached state when service throws limit exception',
      () async {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) => db),
        programmeGenerationServiceProvider
            .overrideWith((ref) => _LimitReachedService(db)),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(programmeGenerationProvider.notifier);
    await notifier.generate(
      ProgrammeGenerationRequest(
        daysPerWeek: 3,
        sessionLengthMinutes: 45,
        exerciseLibrary: const <Exercise>[],
      ),
    );

    expect(
      container.read(programmeGenerationProvider),
      isA<ProgrammeGenerationLimitReached>(),
    );
  });
}
