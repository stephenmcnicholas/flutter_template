import 'package:flutter/material.dart';
import 'package:fytter/src/presentation/theme.dart';

/// A reusable bottom navigation bar for the main app screens.
///
/// Tabs: Exercises, Workouts, Programs, Progress, More
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.themeExt<AppColors>();
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.fitness_center),
          label: 'Exercises',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'Workouts',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list_alt),
          label: 'Programs',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.show_chart),
          label: 'Progress',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz),
          label: 'More',
        ),
      ],
      backgroundColor: colors.surface,
      selectedItemColor: colors.primary,
      unselectedItemColor: colors.outline,
      showUnselectedLabels: true,
    );
  }
}
