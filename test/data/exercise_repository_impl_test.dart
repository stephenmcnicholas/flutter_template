import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:fytter/src/data/exercise_repository_impl.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/exercise_input_type.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late ExerciseRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.test();
    repo = ExerciseRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('save & findAll/findById', () async {
    final e = Exercise(id: 'e1', name: 'Squat', description: 'desc');
    await repo.save(e);

    final all = await repo.findAll();
    expect(all, [e]);

    final found = await repo.findById('e1');
    expect(found, e);
  });

  test('save & find with media paths', () async {
    final e = Exercise(
      id: 'e1',
      name: 'Squat',
      description: 'Compound leg exercise',
      thumbnailPath: 'exercises/thumbnails/squat.jpg',
      mediaPath: 'exercises/media/squat.mp4',
    );
    await repo.save(e);

    final found = await repo.findById('e1');
    expect(found.thumbnailPath, 'exercises/thumbnails/squat.jpg');
    expect(found.mediaPath, 'exercises/media/squat.mp4');
    
    final all = await repo.findAll();
    expect(all.first.thumbnailPath, 'exercises/thumbnails/squat.jpg');
    expect(all.first.mediaPath, 'exercises/media/squat.mp4');
  });

  test('save & find with bodyPart and equipment', () async {
    final e = Exercise(
      id: 'e1',
      name: 'Squat',
      description: 'Compound leg exercise',
      bodyPart: 'Quads',
      equipment: 'Barbell',
    );
    await repo.save(e);

    final found = await repo.findById('e1');
    expect(found.bodyPart, 'Quads');
    expect(found.equipment, 'Barbell');
    
    final all = await repo.findAll();
    expect(all.first.bodyPart, 'Quads');
    expect(all.first.equipment, 'Barbell');
  });

  test('save & find with loggingType', () async {
    final e = Exercise(
      id: 'e1',
      name: 'Push-up',
      description: 'Bodyweight exercise',
      loggingType: ExerciseInputType.repsOnly,
    );
    await repo.save(e);

    final found = await repo.findById('e1');
    expect(found.loggingType, ExerciseInputType.repsOnly);

    final all = await repo.findAll();
    expect(all.first.loggingType, ExerciseInputType.repsOnly);
  });

  test('delete removes exercise', () async {
    final e = Exercise(id: 'e2', name: 'Press');
    await repo.save(e);
    await repo.delete('e2');
    expect(await repo.findAll(), isEmpty);
  });
}