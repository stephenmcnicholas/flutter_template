import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/providers/logger_sheet_provider.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  test('LoggerSheetProvider state transitions', () async {
    final notifier = LoggerSheetNotifier();
    notifier.show(
      workoutName: 'Test',
      workoutId: 'w1',
      initialExercises: [const Exercise(id: '1', name: 'Squat', description: '')],
    );
    expect(notifier.state.visible, true);
    expect(notifier.state.workoutName, 'Test');
    expect(notifier.state.workoutId, 'w1');
    notifier.minimize();
    expect(notifier.state.minimized, true);
    notifier.maximize();
    expect(notifier.state.minimized, false);
    notifier.hide();
    expect(notifier.state.visible, false);
  });

  test('LoggerSessionNotifier basic flow', () {
    final session = LoggerSessionNotifier();
    session.startSession(
      'W1',
      [const Exercise(id: 'e1', name: 'Bench', description: '')],
      null,
      workoutId: 'w1',
    );
    expect(session.state?.workoutName, 'W1');
    expect(session.state?.workoutId, 'w1');
    expect(session.state?.exercises, hasLength(1));

    // addExercise ignores duplicates
    session.addExercise(const Exercise(id: 'e1', name: 'Bench', description: ''));
    expect(session.state?.exercises, hasLength(1));

    // addSet and updateSet
    session.addSet('e1', {'id': 's1', 'reps': 5, 'weight': 50.0, 'isComplete': false});
    expect(session.state?.setsByExercise['e1'], hasLength(1));
    session.updateSet('e1', 0, {'id': 's1', 'reps': 6, 'weight': 55.0, 'isComplete': true});
    expect(session.state?.setsByExercise['e1']?[0]['reps'], 6);

    // removeExercise clears sets
    session.removeExercise('e1');
    expect(session.state?.exercises, isEmpty);
    expect(session.state?.setsByExercise.containsKey('e1'), isFalse);
  });

  test('startSession pre-populates supersetGroups from initial sets supersetGroupId', () {
    final session = LoggerSessionNotifier();
    const groupId = 'group-abc';
    session.startSession(
      'Template Workout',
      [
        const Exercise(id: 'e1', name: 'Squat', description: ''),
        const Exercise(id: 'e2', name: 'Lunge', description: ''),
        const Exercise(id: 'e3', name: 'Press', description: ''),
      ],
      {
        'e1': [{'id': 's1', 'reps': 5, 'weight': 0.0, 'isComplete': false, 'supersetGroupId': groupId}],
        'e2': [{'id': 's2', 'reps': 5, 'weight': 0.0, 'isComplete': false, 'supersetGroupId': groupId}],
        'e3': [{'id': 's3', 'reps': 5, 'weight': 0.0, 'isComplete': false}], // standalone
      },
    );

    expect(session.state?.supersetGroups['e1'], equals(groupId));
    expect(session.state?.supersetGroups['e2'], equals(groupId));
    expect(session.state?.supersetGroups.containsKey('e3'), isFalse);
  });

  test('groupExercisesAsSuperset reorders exercises so group members are consecutive', () {
    // Simulates: user added ChestPress, ChinUp, Crunch, Deadlift in that order,
    // then grouped ChestPress + ChinUp + Deadlift into a circuit.
    // Expected order after grouping: ChestPress, ChinUp, Deadlift, Crunch.
    final session = LoggerSessionNotifier();
    session.startSession(
      'Quick Start',
      [
        const Exercise(id: 'chest', name: 'Chest Press', description: ''),
        const Exercise(id: 'chin', name: 'Chin-Up', description: ''),
        const Exercise(id: 'crunch', name: 'Crunch', description: ''),
        const Exercise(id: 'dead', name: 'Deadlift', description: ''),
      ],
      null,
    );

    session.groupExercisesAsSuperset(['chest', 'chin', 'dead']);

    final ids = session.state!.exercises.map((e) => e.id).toList();
    expect(ids, ['chest', 'chin', 'dead', 'crunch']);
  });

  test('addToGroup moves the exercise to immediately after the last group member', () {
    // Simulates: ChestPress + ChinUp + Deadlift already in a circuit.
    // User then adds Crunch (originally between ChinUp and Deadlift) to the circuit.
    // Expected result: Crunch moves to after Deadlift.
    final session = LoggerSessionNotifier();
    session.startSession(
      'Quick Start',
      [
        const Exercise(id: 'chest', name: 'Chest Press', description: ''),
        const Exercise(id: 'chin', name: 'Chin-Up', description: ''),
        const Exercise(id: 'crunch', name: 'Crunch', description: ''),
        const Exercise(id: 'dead', name: 'Deadlift', description: ''),
      ],
      {
        'chest': [{'id': 's1', 'reps': 5, 'weight': 0.0, 'isComplete': false, 'supersetGroupId': 'g1'}],
        'chin':  [{'id': 's2', 'reps': 5, 'weight': 0.0, 'isComplete': false, 'supersetGroupId': 'g1'}],
        'dead':  [{'id': 's3', 'reps': 5, 'weight': 0.0, 'isComplete': false, 'supersetGroupId': 'g1'}],
        'crunch':[{'id': 's4', 'reps': 10, 'weight': 0.0, 'isComplete': false}],
      },
    );
    // State after load: supersetGroups = {chest: g1, chin: g1, dead: g1}
    // Exercises order: chest, chin, crunch, dead (insertion order)

    session.addToGroup('crunch', 'g1');

    final ids = session.state!.exercises.map((e) => e.id).toList();
    expect(ids, ['chest', 'chin', 'dead', 'crunch']);
    expect(session.state!.supersetGroups['crunch'], 'g1');
  });

  test('groupExercisesAsSuperset stamps groupId on existing sets and new sets', () {
    final session = LoggerSessionNotifier();
    session.startSession(
      'Superset Test',
      [
        const Exercise(id: 'e1', name: 'Squat', description: ''),
        const Exercise(id: 'e2', name: 'Lunge', description: ''),
      ],
      null,
    );
    session.addSet('e1', {'id': 's1', 'reps': 5, 'weight': 60.0, 'isComplete': false});
    session.addSet('e2', {'id': 's2', 'reps': 10, 'weight': 0.0, 'isComplete': false});

    session.groupExercisesAsSuperset(['e1', 'e2']);

    // Both exercises' existing sets should have the same non-null supersetGroupId.
    final groupId1 = session.state?.setsByExercise['e1']?[0]['supersetGroupId'] as String?;
    final groupId2 = session.state?.setsByExercise['e2']?[0]['supersetGroupId'] as String?;
    expect(groupId1, isNotNull);
    expect(groupId1, equals(groupId2));

    // supersetGroups map should reflect the grouping.
    expect(session.state?.supersetGroups['e1'], equals(groupId1));
    expect(session.state?.supersetGroups['e2'], equals(groupId1));

    // New sets added after grouping should also carry the groupId.
    session.addSet('e1', {'id': 's3', 'reps': 5, 'weight': 60.0, 'isComplete': false});
    final newSetGroupId = session.state?.setsByExercise['e1']?[1]['supersetGroupId'] as String?;
    expect(newSetGroupId, equals(groupId1));
  });

  test('groupExercisesAsSuperset ignores request with fewer than 2 exercises', () {
    final session = LoggerSessionNotifier();
    session.startSession(
      'W',
      [const Exercise(id: 'e1', name: 'Squat', description: '')],
      null,
    );
    session.groupExercisesAsSuperset(['e1']); // only 1 — should be a no-op
    expect(session.state?.supersetGroups, isEmpty);
  });

  test('removeExercise cleans up supersetGroups', () {
    final session = LoggerSessionNotifier();
    session.startSession(
      'W',
      [
        const Exercise(id: 'e1', name: 'Squat', description: ''),
        const Exercise(id: 'e2', name: 'Lunge', description: ''),
      ],
      null,
    );
    session.addSet('e1', {'id': 's1', 'reps': 5, 'weight': 0.0, 'isComplete': false});
    session.addSet('e2', {'id': 's2', 'reps': 5, 'weight': 0.0, 'isComplete': false});
    session.groupExercisesAsSuperset(['e1', 'e2']);
    expect(session.state?.supersetGroups.containsKey('e1'), isTrue);

    session.removeExercise('e1');
    expect(session.state?.supersetGroups.containsKey('e1'), isFalse);
    // e2 still in the group
    expect(session.state?.supersetGroups.containsKey('e2'), isTrue);
  });
} 