import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/presentation/progress/workout_frequency_tab.dart';
import 'package:fytter/src/presentation/progress/program_stats_tab.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TabBarView(
      children: [
        WorkoutFrequencyTab(),
        ProgramStatsTab(),
      ],
    );
  }
} 