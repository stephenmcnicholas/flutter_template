import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/domain/workout_entry.dart';
import 'package:uuid/uuid.dart';

class WorkoutLoggerScreen extends ConsumerStatefulWidget {
  const WorkoutLoggerScreen({super.key});
  @override
  WorkoutLoggerScreenState createState() => WorkoutLoggerScreenState();
}

class WorkoutLoggerScreenState extends ConsumerState<WorkoutLoggerScreen> {
  bool _inSession = false;
  final List<WorkoutEntry> _entries = [];
  final _uuid = const Uuid();

  void _startOrEnd() {
    if (_inSession) {
      // End workout: persist entries
      final repo = ref.read(workoutEntryRepositoryProvider);
      for (var e in _entries) {
        repo.save(e);
      }
      _entries.clear();
    }
    setState(() => _inSession = !_inSession);
  }

  void _addSet() {
    // For now, add a dummy set; later wire up a form
    final now = DateTime.now();
    setState(() {
      _entries.add(WorkoutEntry(
        id: _uuid.v4(), // Use UUID to prevent ID collisions
        exerciseId: 'e1',        // TODO: let user pick exercise
        reps: 5,
        weight: 50.0,
        isComplete: false,
        timestamp: now,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout Logger')),
      body: Column(
        children: [
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _startOrEnd,
            child: Text(_inSession ? 'End Workout' : 'Start Workout'),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _entries.isEmpty
                ? const Center(child: Text('No sets yet'))
                : ListView.builder(
                    itemCount: _entries.length,
                    itemBuilder: (_, i) {
                      final e = _entries[i];
                      return ListTile(
                        title: Text('Reps: ${e.reps}, Weight: ${e.weight}kg'),
                        subtitle: Text(
                          TimeOfDay.fromDateTime(e.timestamp ?? DateTime.now()).format(context),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _inSession
          ? FloatingActionButton(
              onPressed: _addSet,
              tooltip: 'Add set',
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: const StadiumBorder(),
              elevation: 6,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}