import 'package:flutter/material.dart';
import 'package:fytter/src/presentation/shared/app_sheet_transition.dart';

/// Prompts the user to enter a workout name. Returns the entered name, or null if cancelled.
Future<String?> showWorkoutNameDialog(BuildContext context, {String? initial}) async {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Workout Name'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Enter workout name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

/// Prompts the user to enter a program name. Returns the entered name, or null if cancelled.
Future<String?> showProgramNameDialog(BuildContext context, {String? initial}) async {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Program Name'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Enter program name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

enum ProgramDateChangeScope { single, shiftAll }

Future<ProgramDateChangeScope?> showProgramDateChangeScopeDialog(
  BuildContext context, {
  String title = 'Apply date change',
  String message = 'Do you want to change only this workout or shift the entire program?',
  String singleLabel = 'Only this workout',
  String shiftAllLabel = 'Shift all workouts',
}) {
  return showDialog<ProgramDateChangeScope>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(ProgramDateChangeScope.single),
          child: Text(singleLabel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(ProgramDateChangeScope.shiftAll),
          child: Text(shiftAllLabel),
        ),
      ],
    ),
  );
}

Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmText),
        ),
      ],
    ),
  );
}

Future<void> showInfoDialog(
  BuildContext context, {
  required String title,
  required String message,
  String buttonText = 'OK',
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(buttonText),
        ),
      ],
    ),
  );
}

/// Prompts the user to enter reps and weight for a set. Returns a map { 'reps': int, 'weight': double } or null if cancelled.
Future<Map<String, dynamic>?> showSetInputBottomSheet(BuildContext context, {int? initialReps, double? initialWeight}) async {
  final repsController = TextEditingController(text: initialReps?.toString() ?? '');
  final weightController = TextEditingController(text: initialWeight?.toString() ?? '');
  final repsFocusNode = FocusNode();
  final weightFocusNode = FocusNode();
  final formKey = GlobalKey<FormState>();
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return AppSheetTransition(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Set Details', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                TextFormField(
                  controller: repsController,
                  focusNode: repsFocusNode,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Reps'),
                  validator: (value) {
                    final reps = int.tryParse(value ?? '');
                    if (reps == null || reps <= 0) return 'Enter a positive number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: weightController,
                  focusNode: weightFocusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Weight (kg)'),
                  validator: (value) {
                    final weight = double.tryParse(value ?? '');
                    if (weight == null || weight < 0) return 'Enter a valid weight';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState?.validate() ?? false) {
                          Navigator.of(context).pop({
                            'reps': int.parse(repsController.text),
                            'weight': double.parse(weightController.text),
                          });
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
