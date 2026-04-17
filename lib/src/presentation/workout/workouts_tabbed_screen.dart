import 'package:flutter/material.dart';
import 'package:fytter/src/presentation/history/history_list_screen.dart';
import 'package:fytter/src/presentation/workout/workout_templates_screen.dart';

class WorkoutsTabbedScreen extends StatelessWidget {
  const WorkoutsTabbedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      children: [
        HistoryListScreen(),
        WorkoutTemplatesScreen(),
      ],
    );
  }
} 