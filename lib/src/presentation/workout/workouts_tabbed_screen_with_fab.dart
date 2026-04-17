import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'workouts_tabbed_screen.dart';
import 'package:fytter/src/domain/exercise.dart';

class WorkoutsTabbedScreenWithFab extends StatefulWidget {
  final Widget Function(Widget body, Widget? fab) builder;
  final void Function(String workoutName, {List<Exercise> initialExercises, Map<String, List<Map<String, dynamic>>>? initialSetsByExercise}) onQuickstart;
  const WorkoutsTabbedScreenWithFab({super.key, required this.builder, required this.onQuickstart});

  @override
  State<WorkoutsTabbedScreenWithFab> createState() => _WorkoutsTabbedScreenWithFabState();
}

class _WorkoutsTabbedScreenWithFabState extends State<WorkoutsTabbedScreenWithFab> {
  TabController? _tabController;
  int _tabIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = DefaultTabController.of(context);
    if (_tabController != controller) {
      _tabController?.removeListener(_handleTabChange);
      _tabController = controller;
      _tabController?.addListener(_handleTabChange);
      _tabIndex = _tabController?.index ?? 0;
    }
  }

  void _handleTabChange() {
    if (mounted && _tabController != null && _tabIndex != _tabController!.index) {
      setState(() {
        _tabIndex = _tabController!.index;
      });
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(_handleTabChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget? fab = SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      tooltip: 'Actions',
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.add),
          label: 'Create Workout Template',
          onTap: () => GoRouter.of(context).push('/workouts/new'),
        ),
        SpeedDialChild(
          child: const Icon(Icons.fitness_center),
          label: 'Quickstart Workout',
          onTap: () {
            debugPrint('FAB: Quickstart Workout tapped');
            widget.onQuickstart('Quick Start');
          },
        ),
      ],
    );
    return widget.builder(WorkoutsTabbedScreen(), fab);
  }
} 