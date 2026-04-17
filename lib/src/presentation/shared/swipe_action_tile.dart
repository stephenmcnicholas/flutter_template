import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class SwipeActionTile extends StatelessWidget {
  final Widget child;
  final VoidCallback onDelete;
  final VoidCallback onReplace;
  final bool showReplace;
  final VoidCallback? onStart;

  const SwipeActionTile({
    super.key,
    required this.child,
    required this.onDelete,
    required this.onReplace,
    this.showReplace = true,
    this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: key,
      startActionPane: onStart != null
          ? ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.2,
              children: [
                SlidableAction(
                  onPressed: (_) => onStart!(),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  icon: Icons.play_arrow,
                  label: '',
                  autoClose: true,
                ),
              ],
            )
          : null,
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: showReplace ? 0.4 : 0.2,
        children: [
          if (showReplace)
            SlidableAction(
              onPressed: (_) => onReplace(),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
              icon: Icons.swap_horiz,
              label: '',
              autoClose: true,
            ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
            icon: Icons.close,
            label: '',
            autoClose: true,
          ),
        ],
      ),
      child: child,
    );
  }
} 