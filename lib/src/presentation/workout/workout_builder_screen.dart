import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:fytter/src/domain/workout.dart';
import 'package:fytter/src/domain/workout_entry.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:fytter/src/presentation/workout/workout_templates_screen.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/presentation/shared/swipe_action_tile.dart';
import 'package:fytter/src/presentation/shared/exercise_card.dart';
import 'package:fytter/src/domain/exercise_input_type.dart';
import 'package:fytter/src/utils/exercise_utils.dart';
import 'package:fytter/src/providers/exercise_history_provider.dart';
import 'package:fytter/src/providers/unit_settings_provider.dart';

class WorkoutBuilderScreen extends ConsumerStatefulWidget {
  final String? workoutId;
  const WorkoutBuilderScreen({super.key, this.workoutId});

  @override
  ConsumerState<WorkoutBuilderScreen> createState() => _WorkoutBuilderScreenState();
}

class _WorkoutBuilderScreenState extends ConsumerState<WorkoutBuilderScreen> {
  String _name = '';
  final List<String> _selectedExerciseIds = []; // List to preserve order
  final Map<String, List<WorkoutEntry>> _setsByExercise = {};
  final Map<String, bool> _expandedByExerciseId = {};
  /// Maps exerciseId → groupId for exercises that belong to a superset.
  final Map<String, String> _supersetGroups = {};
  bool _isLoading = false;
  bool _initialized = false;
  late final TextEditingController _controller;
  final _uuid = Uuid();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized && widget.workoutId != null) {
      _isLoading = true;
      final repo = ref.read(workoutRepositoryProvider);
      repo.findById(widget.workoutId!).then((workout) {
        setState(() {
          _name = workout.name;
          _controller.text = workout.name;
          _selectedExerciseIds.clear();
          _setsByExercise.clear();
          _supersetGroups.clear();
          // Preserve order from workout entries
          final seenIds = <String>{};
          for (final entry in workout.entries) {
            if (!seenIds.contains(entry.exerciseId)) {
              _selectedExerciseIds.add(entry.exerciseId);
              seenIds.add(entry.exerciseId);
            }
            _setsByExercise.putIfAbsent(entry.exerciseId, () => []).add(entry);
            // Restore superset group associations
            if (entry.supersetGroupId != null) {
              _supersetGroups[entry.exerciseId] = entry.supersetGroupId!;
            }
          }
          _isLoading = false;
          _initialized = true;
        });
      }).catchError((_) {
        setState(() {
          _isLoading = false;
          _initialized = true;
        });
      });
    } else if (!_initialized) {
      _controller.text = _name;
      _initialized = true;
    }
  }

  void _addExercise(String exId) {
    if (!_selectedExerciseIds.contains(exId)) {
      _selectedExerciseIds.add(exId);
    }
    _expandedByExerciseId[exId] = true;
    final sets = _setsByExercise.putIfAbsent(exId, () => <WorkoutEntry>[]);
    if (sets.isEmpty) {
      sets.add(
        WorkoutEntry(
          id: _uuid.v4(),
          exerciseId: exId,
          reps: 0,
          weight: 0.0,
          isComplete: false,
          timestamp: null,
          sessionId: null,
        ),
      );
    }
  }

  void _removeExercise(String exId) {
    setState(() {
      _selectedExerciseIds.remove(exId);
      _setsByExercise.remove(exId);
      _expandedByExerciseId.remove(exId);
      // Dissolve group if removing drops it to < 2 members
      final groupId = _supersetGroups.remove(exId);
      if (groupId != null) {
        final remaining = _selectedExerciseIds
            .where((id) => _supersetGroups[id] == groupId)
            .toList();
        if (remaining.length == 1) {
          _supersetGroups.remove(remaining.first);
        }
      }
    });
  }

  /// Removes [exId] from its superset group without deleting the exercise.
  /// Dissolves the group if it falls below 2 members.
  void _ungroupExercise(String exId) {
    setState(() {
      final groupId = _supersetGroups.remove(exId);
      if (groupId != null) {
        final remaining = _selectedExerciseIds
            .where((id) => _supersetGroups[id] == groupId)
            .toList();
        if (remaining.length == 1) {
          _supersetGroups.remove(remaining.first);
        }
      }
    });
  }

  void _replaceExercise(String oldExId, String newExId) {
    setState(() {
      final sets = _setsByExercise[oldExId];
      final oldIndex = _selectedExerciseIds.indexOf(oldExId);
      _selectedExerciseIds.remove(oldExId);
      _setsByExercise.remove(oldExId);
      // Insert at the same position to preserve order
      if (oldIndex >= 0 && oldIndex < _selectedExerciseIds.length) {
        _selectedExerciseIds.insert(oldIndex, newExId);
      } else {
        _selectedExerciseIds.add(newExId);
      }
      _setsByExercise[newExId] = sets
              ?.map((entry) => WorkoutEntry(
                    id: entry.id,
                    exerciseId: newExId,
                    reps: entry.reps,
                    weight: entry.weight,
                    isComplete: entry.isComplete,
                    timestamp: entry.timestamp,
                    sessionId: entry.sessionId,
                  ))
              .toList() ??
          [];
    });
  }

  void _reorderExercises(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    setState(() {
      final tokens = _buildRenderTokenList();
      if (oldIndex < 0 || oldIndex >= tokens.length) return;
      if (newIndex < 0 || newIndex >= tokens.length) return;
      final movedToken = tokens.removeAt(oldIndex);
      tokens.insert(newIndex, movedToken);
      _selectedExerciseIds
        ..clear()
        ..addAll(tokens.expand((t) => t));
    });
  }

  Future<void> _addSet(String exId) async {
    _setsByExercise[exId] ??= [];
    final existingSets = _setsByExercise[exId]!;

    // If there are already sets, copy the last one's values.
    if (existingSets.isNotEmpty) {
      final last = existingSets.last;
      setState(() {
        existingSets.add(WorkoutEntry(
          id: _uuid.v4(),
          exerciseId: exId,
          reps: last.reps,
          weight: last.weight,
          distance: last.distance,
          duration: last.duration,
          isComplete: false,
        ));
      });
      return;
    }

    // First set: use last recorded values or sensible defaults.
    final allExercises = ref.read(exercisesFutureProvider).value ?? [];
    final exercise = allExercises.firstWhere((e) => e.id == exId);
    final inputType = getExerciseInputType(exercise);

    LastRecordedValues? lastValues;
    try {
      lastValues = await ref.read(lastRecordedValuesProvider(exId).future);
    } catch (_) {
      lastValues = null;
    }

    int defaultReps = 0;
    double defaultWeight = 0.0;
    double? defaultDistance;
    int? defaultDuration;

    switch (inputType) {
      case ExerciseInputType.repsAndWeight:
        defaultReps = lastValues?.reps ?? 10;
        defaultWeight = lastValues?.weight ?? 0.0;
        break;
      case ExerciseInputType.repsOnly:
        defaultReps = lastValues?.reps ?? 10;
        defaultWeight = 0.0;
        break;
      case ExerciseInputType.distanceAndTime:
        defaultDistance = lastValues?.distance ?? 5.0;
        defaultDuration = lastValues?.duration ?? 1800;
        break;
      case ExerciseInputType.timeOnly:
        defaultDuration = lastValues?.duration ?? 60;
        break;
    }
    
    setState(() {
      _setsByExercise[exId]!.add(WorkoutEntry(
        id: _uuid.v4(),
        exerciseId: exId,
        reps: defaultReps,
        weight: defaultWeight,
        distance: defaultDistance,
        duration: defaultDuration,
        isComplete: false,
        timestamp: null,
        sessionId: null,
      ));
    });
  }

  void _removeSet(String exId, int setIndex) {
    setState(() {
      _setsByExercise[exId]?.removeAt(setIndex);
    });
  }

  void _updateSet(String exId, int setIndex, {int? reps, double? weight, double? distance, int? duration}) {
    setState(() {
      final set = _setsByExercise[exId]![setIndex];
      _setsByExercise[exId]![setIndex] = WorkoutEntry(
        id: set.id,
        exerciseId: set.exerciseId,
        reps: reps ?? set.reps,
        weight: weight ?? set.weight,
        distance: distance ?? set.distance,
        duration: duration ?? set.duration,
        isComplete: set.isComplete,
        timestamp: set.timestamp,
        sessionId: set.sessionId,
      );
    });
  }

  void _showExercisePicker(BuildContext context, List<Exercise> allExercises) async {
    // Navigate to exercise selection screen with already selected IDs
    final uri = Uri(
      path: '/exercises/select',
      queryParameters: _selectedExerciseIds.isNotEmpty
          ? {'alreadySelected': _selectedExerciseIds.join(',')}
          : null,
    );
    final selectedIds = await context.push<List<String>>(uri.toString());
    if (selectedIds != null && selectedIds.isNotEmpty) {
      setState(() {
        for (final exId in selectedIds) {
          _addExercise(exId);
        }
      });
    }
  }

  void _showReplaceExercisePicker(
    BuildContext context,
    Exercise exerciseToReplace,
  ) async {
    final blockedIds = [
      for (final id in _selectedExerciseIds)
        if (id != exerciseToReplace.id) id,
    ];
    final uri = Uri(
      path: '/exercises/select',
      queryParameters: {
        if (blockedIds.isNotEmpty) 'alreadySelected': blockedIds.join(','),
        'singleSelection': 'true',
        'title': 'Replace Exercise',
        'actionLabel': 'Replace',
      },
    );
    final selectedIds = await context.push<List<String>>(uri.toString());
    if (selectedIds == null || selectedIds.isEmpty) return;
    _replaceExercise(exerciseToReplace.id, selectedIds.first);
  }

  Future<void> _showSupersetPicker(
    BuildContext context,
    List<Exercise> allExercises,
  ) async {
    if (_selectedExerciseIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add exercises to your workout first, then group them into a superset.'),
        ),
      );
      return;
    }

    final ungroupedIds = _selectedExerciseIds
        .where((id) => !_supersetGroups.containsKey(id))
        .toList();

    if (ungroupedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All exercises are already in supersets.')),
      );
      return;
    }

    final ungroupedExercises = allExercises
        .where((e) => ungroupedIds.contains(e.id))
        .toList();

    final picked = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _SupersetPickerSheet(exercises: ungroupedExercises),
    );

    if (picked == null || picked.length < 2) return;

    final groupId = _uuid.v4();
    setState(() {
      for (final id in picked) {
        _supersetGroups[id] = groupId;
      }
    });
  }

  /// Returns a list of render tokens. Each token is a list of exercise IDs.
  /// Standalone exercises: [exId]. Groups: [exId1, exId2, ...] in list order.
  List<List<String>> _buildRenderTokenList() {
    final result = <List<String>>[];
    final processed = <String>{};
    for (final exId in _selectedExerciseIds) {
      if (processed.contains(exId)) continue;
      final groupId = _supersetGroups[exId];
      if (groupId != null) {
        final groupExIds = _selectedExerciseIds
            .where((id) => _supersetGroups[id] == groupId)
            .toList();
        result.add(groupExIds);
        processed.addAll(groupExIds);
      } else {
        result.add([exId]);
        processed.add(exId);
      }
    }
    return result;
  }

  void _moveWithinGroup(String groupId, int oldGroupIndex, int newGroupIndex) {
    setState(() {
      final groupExIds = _selectedExerciseIds
          .where((id) => _supersetGroups[id] == groupId)
          .toList();
      final exIdA = groupExIds[oldGroupIndex];
      final exIdB = groupExIds[newGroupIndex];
      final globalA = _selectedExerciseIds.indexOf(exIdA);
      final globalB = _selectedExerciseIds.indexOf(exIdB);
      _selectedExerciseIds[globalA] = exIdB;
      _selectedExerciseIds[globalB] = exIdA;
    });
  }

  Widget _buildGroupCard(
    String groupId,
    List<String> groupExIds,
    List<Exercise> allExercises,
    dynamic unitSettings,
    int tokenIndex, {
    bool isDropTarget = false,
  }) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      key: ValueKey('group_$groupId'),
      decoration: BoxDecoration(
        border: Border.all(color: primary, width: isDropTarget ? 3 : 1.5),
        borderRadius: BorderRadius.circular(12),
        color: isDropTarget ? primary.withValues(alpha: 0.06) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Text(
                  'SUPERSET',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                ReorderableDragStartListener(
                  index: tokenIndex,
                  child: Icon(
                    Icons.drag_handle,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
          ...groupExIds.asMap().entries.map((entry) {
            final groupIndex = entry.key;
            final exId = entry.value;
            final ex = allExercises.firstWhere(
              (e) => e.id == exId,
              orElse: () => Exercise(id: exId, name: exId, description: ''),
            );
            final sets = _setsByExercise[exId] ?? [];
            final isExpanded = _expandedByExerciseId[exId] ?? true;
            final cardChild = SwipeActionTile(
              key: ValueKey('group_swipe_$exId'),
              showReplace: false,
              onDelete: () => _removeExercise(exId),
              onReplace: () {},
              child: ExerciseCard(
                exerciseName: ex.name,
                inputType: getExerciseInputType(ex),
                weightUnit: unitSettings.weightUnit,
                distanceUnit: unitSettings.distanceUnit,
                isExpanded: isExpanded,
                onHeaderTap: () => setState(() {
                  _expandedByExerciseId[exId] = !isExpanded;
                }),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (groupIndex > 0)
                      IconButton(
                        icon: const Icon(Icons.arrow_upward),
                        iconSize: 16,
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Move up',
                        onPressed: () => _moveWithinGroup(
                            groupId, groupIndex, groupIndex - 1),
                      ),
                    if (groupIndex < groupExIds.length - 1)
                      IconButton(
                        icon: const Icon(Icons.arrow_downward),
                        iconSize: 16,
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Move down',
                        onPressed: () => _moveWithinGroup(
                            groupId, groupIndex, groupIndex + 1),
                      ),
                  ],
                ),
                onAddSet: () => _addSet(exId),
                setList: sets.asMap().entries.map((setEntry) {
                  final setIndex = setEntry.key;
                  final set = setEntry.value;
                  return SwipeActionTile(
                    key: ValueKey('set_tile_${set.id}'),
                    showReplace: false,
                    onDelete: () => _removeSet(exId, setIndex),
                    onReplace: () {},
                    child: SetEditor(
                      key: ValueKey('set_editor_${set.id}'),
                      set: set,
                      inputType: getExerciseInputType(ex),
                      setNumber: setIndex + 1,
                      weightUnit: unitSettings.weightUnit,
                      distanceUnit: unitSettings.distanceUnit,
                      onChanged: (reps, weight, distance, duration) =>
                          _updateSet(exId, setIndex,
                              reps: reps,
                              weight: weight,
                              distance: distance,
                              duration: duration),
                      onDelete: () => _removeSet(exId, setIndex),
                    ),
                  );
                }).toList(),
              ),
            );
            return LongPressDraggable<String>(
              key: ValueKey('group_draggable_$exId'),
              data: exId,
              feedback: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Text(
                    ex.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer,
                    ),
                  ),
                ),
              ),
              childWhenDragging: Opacity(opacity: 0.3, child: cardChild),
              onDragEnd: (details) {
                if (!details.wasAccepted) {
                  _ungroupExercise(exId);
                }
              },
              child: cardChild,
            );
          }),
          TextButton(
            onPressed: () async {
              final uri = Uri(
                path: '/exercises/select',
                queryParameters: {
                  'alreadySelected': _selectedExerciseIds.join(','),
                  'singleSelection': 'true',
                  'title': 'Add to Superset',
                  'actionLabel': 'Add',
                },
              );
              final selectedIds =
                  await context.push<List<String>>(uri.toString());
              if (selectedIds == null || selectedIds.isEmpty) return;
              final exId = selectedIds.first;
              setState(() {
                _addExercise(exId);
                _supersetGroups[exId] = groupId;
              });
            },
            child: const Text('+ Add exercise to superset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exercisesFutureProvider);
    final unitSettings = ref.watch(unitSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workoutId == null ? 'New Workout Template' : 'Edit Workout Template'),
        actions: [
          if (widget.workoutId != null)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete workout template',
              onPressed: () async {
                final repo = ref.read(workoutRepositoryProvider);
                final navigator = GoRouter.of(context);
                await repo.delete(widget.workoutId!);
                if (!mounted) return;
                navigator.pop();
                ref.invalidate(workoutTemplatesFutureProvider);
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : exercisesAsync.when(
              data: (allExercises) => GestureDetector(
                onTap: () {
                  // Dismiss keyboard when tapping outside text fields
                  FocusScope.of(context).unfocus();
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Workout name input
                    TextField(
                      key: const Key('workoutName'),
                      decoration: const InputDecoration(labelText: 'Workout Name'),
                      controller: _controller,
                      onChanged: (value) => setState(() {
                        _name = value;
                      }),
                    ),
                    const SizedBox(height: 24),
                    // Add Exercise / Superset Buttons
                    Row(
                      children: [
                        const Spacer(),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            side: BorderSide(
                                color:
                                    Theme.of(context).colorScheme.outline),
                            textStyle: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          onPressed: () =>
                              _showSupersetPicker(context, allExercises),
                          child: const Text('Superset'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Exercise'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            textStyle: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600),
                            elevation: 0,
                          ),
                          onPressed: () =>
                              _showExercisePicker(context, allExercises),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Exercise selection list with drag-to-reorder
                    Expanded(
                      child: ReorderableListView(
                        buildDefaultDragHandles: false,
                        onReorder: _reorderExercises,
                        children: () {
                          final tokens = _buildRenderTokenList();
                          final widgets = <Widget>[];
                          for (var i = 0; i < tokens.length; i++) {
                            final token = tokens[i];
                            final isGroup = token.length > 1 ||
                                (token.isNotEmpty &&
                                    _supersetGroups
                                        .containsKey(token.first));
                            if (isGroup) {
                              final groupId =
                                  _supersetGroups[token.first]!;
                              widgets.add(
                                Padding(
                                  key: ValueKey('group_$groupId'),
                                  padding: const EdgeInsets.only(
                                      bottom: 20.0),
                                  child: DragTarget<String>(
                                    onWillAcceptWithDetails: (details) =>
                                        _supersetGroups[details.data] !=
                                        groupId,
                                    onAcceptWithDetails: (details) {
                                      setState(() {
                                        // Dissolve source group if it now has < 2 members.
                                        final oldGroupId = _supersetGroups[details.data];
                                        _supersetGroups[details.data] = groupId;
                                        if (oldGroupId != null) {
                                          final remaining = _selectedExerciseIds
                                              .where((id) => _supersetGroups[id] == oldGroupId)
                                              .toList();
                                          if (remaining.length == 1) {
                                            _supersetGroups.remove(remaining.first);
                                          }
                                        }
                                      });
                                    },
                                    builder: (context, candidateData,
                                            rejectedData) =>
                                        _buildGroupCard(
                                      groupId,
                                      token,
                                      allExercises,
                                      unitSettings,
                                      i,
                                      isDropTarget:
                                          candidateData.isNotEmpty,
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              final exId = token.first;
                              final ex = allExercises
                                  .firstWhere((e) => e.id == exId);
                              final sets =
                                  _setsByExercise[exId] ?? [];
                              final isExpanded =
                                  _expandedByExerciseId[exId] ?? true;
                              final cardChild = SwipeActionTile(
                                    key: ValueKey('swipe_tile_$exId'),
                                    onDelete: () =>
                                        _removeExercise(exId),
                                    onReplace: () =>
                                        _showReplaceExercisePicker(
                                            context, ex),
                                    child: ExerciseCard(
                                      exerciseName: ex.name,
                                      inputType:
                                          getExerciseInputType(ex),
                                      weightUnit:
                                          unitSettings.weightUnit,
                                      distanceUnit:
                                          unitSettings.distanceUnit,
                                      isExpanded: isExpanded,
                                      onHeaderTap: () {
                                        setState(() {
                                          _expandedByExerciseId[
                                                  exId] =
                                              !isExpanded;
                                        });
                                      },
                                      trailing:
                                          ReorderableDragStartListener(
                                        index: i,
                                        child: Icon(
                                          Icons.drag_handle,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline,
                                        ),
                                      ),
                                      onAddSet: () => _addSet(exId),
                                      setList: sets
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        final setIndex = entry.key;
                                        final set = entry.value;
                                        return SwipeActionTile(
                                          key: ValueKey(
                                              'set_tile_${set.id}'),
                                          showReplace: false,
                                          onDelete: () => _removeSet(
                                              exId, setIndex),
                                          onReplace: () {},
                                          child: SetEditor(
                                            key: ValueKey(
                                                'set_editor_${set.id}'),
                                            set: set,
                                            inputType:
                                                getExerciseInputType(
                                                    ex),
                                            setNumber: setIndex + 1,
                                            weightUnit:
                                                unitSettings.weightUnit,
                                            distanceUnit: unitSettings
                                                .distanceUnit,
                                            onChanged: (reps, weight,
                                                    distance,
                                                    duration) =>
                                                _updateSet(exId,
                                                    setIndex,
                                                    reps: reps,
                                                    weight: weight,
                                                    distance: distance,
                                                    duration: duration),
                                            onDelete: () => _removeSet(
                                                exId, setIndex),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  );
                              widgets.add(
                                Padding(
                                  key: ValueKey('exercise_$exId'),
                                  padding: const EdgeInsets.only(
                                      bottom: 20.0),
                                  child: LongPressDraggable<String>(
                                    data: exId,
                                    feedback: Material(
                                      elevation: 4,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                      child: Padding(
                                        padding: const EdgeInsets
                                            .symmetric(
                                            horizontal: 16,
                                            vertical: 12),
                                        child: Text(
                                          ex.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                    ),
                                    childWhenDragging: Opacity(
                                      opacity: 0.3,
                                      child: cardChild,
                                    ),
                                    child: cardChild,
                                  ),
                                ),
                              );
                            }
                          }
                          return widgets;
                        }(),
                      ),
                    ),
                  ],
                ),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          // Enabled only when name is non-empty AND at least one exercise is selected
          onPressed: (_name.trim().isEmpty || _selectedExerciseIds.isEmpty)
              ? null
              : () async {
                  final repo = ref.read(workoutRepositoryProvider);
                  final uuid = const Uuid();
                  // Flatten all sets for all selected exercises into WorkoutEntry list.
                  // Use render-token order so superset exercises are always consecutive,
                  // matching the visual order shown in the builder.
                  final orderedExIds = _buildRenderTokenList().expand((t) => t).toList();
                  final entries = <WorkoutEntry>[];
                  for (final exId in orderedExIds) {
                    final groupId = _supersetGroups[exId];
                    final sets = _setsByExercise[exId] ?? [];
                    if (sets.isEmpty) {
                      // If an exercise is selected but has no sets, add a default
                      // entry so it's included in the template.
                      entries.add(WorkoutEntry(
                        id: _uuid.v4(),
                        exerciseId: exId,
                        reps: 0,
                        weight: 0.0,
                        isComplete: false,
                        timestamp: null,
                        sessionId: null,
                        supersetGroupId: groupId,
                      ));
                    } else {
                      for (final set in sets) {
                        entries.add(WorkoutEntry(
                          id: set.id,
                          exerciseId: set.exerciseId,
                          reps: set.reps,
                          weight: set.weight,
                          distance: set.distance,
                          duration: set.duration,
                          isComplete: set.isComplete,
                          timestamp: set.timestamp,
                          sessionId: set.sessionId,
                          setOutcome: set.setOutcome,
                          supersetGroupId: groupId,
                        ));
                      }
                    }
                  }

                  final workout = Workout(
                    id: widget.workoutId ?? uuid.v4(),
                    name: _name.trim(),
                    entries: entries,
                  );
                  final navigator = GoRouter.of(context);
                  await repo.save(workout);
                  ref.invalidate(workoutTemplatesFutureProvider);
                  navigator.go('/');
                },
          child: const Text('Save'),
        ),
      ),
    );
  }
}

/// Bottom sheet for selecting ≥2 ungrouped exercises to create a superset.
class _SupersetPickerSheet extends StatefulWidget {
  final List<Exercise> exercises;
  const _SupersetPickerSheet({required this.exercises});

  @override
  State<_SupersetPickerSheet> createState() => _SupersetPickerSheetState();
}

class _SupersetPickerSheetState extends State<_SupersetPickerSheet> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                'Create superset',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Select 2 or more exercises to group together.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
            ...widget.exercises.map(
              (ex) => CheckboxListTile(
                value: _selected.contains(ex.id),
                title: Text(ex.name),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selected.add(ex.id);
                    } else {
                      _selected.remove(ex.id);
                    }
                  });
                },
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ElevatedButton(
                onPressed: _selected.length >= 2
                    ? () => Navigator.of(context).pop(_selected.toList())
                    : null,
                child: const Text('Create superset'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}