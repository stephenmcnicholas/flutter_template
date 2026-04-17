import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fytter/src/domain/workout_entry.dart';
import 'package:fytter/src/domain/exercise_input_type.dart';
import 'package:fytter/src/presentation/shared/app_card.dart';
import 'package:fytter/src/presentation/shared/app_text.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/utils/format_utils.dart' show
  formatDuration,
  parseDuration,
  parseDistance,
  TimeInputFormatter,
  isValidTime,
  WeightUnit,
  DistanceUnit,
  weightUnitLabel,
  distanceUnitLabel,
  formatWeightValue,
  formatDistanceValue,
  convertWeightToStorage,
  convertDistanceToStorage;
//import 'package:fytter/src/presentation/shared/swipe_action_tile.dart';

class ExerciseCard extends StatefulWidget {
  final String exerciseName;
  final List<Widget> setList;
  final VoidCallback onAddSet;
  final Widget? trailing;
  final VoidCallback? onDeleteExercise;
  final VoidCallback? onReplaceExercise;
  final ExerciseInputType inputType;
  final WeightUnit weightUnit;
  final DistanceUnit distanceUnit;
  final bool isExpanded;
  final VoidCallback? onHeaderTap;
  const ExerciseCard({
    super.key,
    required this.exerciseName,
    required this.setList,
    required this.onAddSet,
    this.trailing,
    this.onDeleteExercise,
    this.onReplaceExercise,
    this.inputType = ExerciseInputType.repsAndWeight,
    this.weightUnit = WeightUnit.kg,
    this.distanceUnit = DistanceUnit.km,
    this.isExpanded = false,
    this.onHeaderTap,
  });

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard> {
  @override
  Widget build(BuildContext context) {
    final spacing = context.themeExt<AppSpacing>();
    final colors = context.themeExt<AppColors>();
    
    return AppCard(
      elevation: 2,
      padding: EdgeInsets.all(spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: widget.onHeaderTap,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Expanded(
                  child: AppText(
                    widget.exerciseName,
                    style: AppTextStyle.label,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.trailing != null) ...[
                  widget.trailing!,
                  SizedBox(width: spacing.xs),
                ],
                AnimatedRotation(
                  turns: widget.isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more,
                    color: colors.outline,
                  ),
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            crossFadeState: widget.isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
            firstChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: spacing.lg),
                Padding(
                  padding: EdgeInsets.only(
                    left: spacing.sm,
                    right: spacing.sm,
                    bottom: spacing.sm,
                  ),
                  child: _buildHeaderRow(spacing),
                ),
                ...widget.setList,
                SizedBox(height: spacing.lg),
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Set'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      textStyle:
                          const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onPressed: widget.onAddSet,
                  ),
                ),
              ],
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(AppSpacing spacing) {
    switch (widget.inputType) {
      case ExerciseInputType.repsAndWeight:
        return Row(
          children: [
            const SizedBox(width: 40),
            SizedBox(width: spacing.lg),
            Expanded(
              child: AppText(
                'Reps',
                style: AppTextStyle.caption,
              ),
            ),
            SizedBox(width: spacing.md),
            Expanded(
              child: AppText(
                'Weight (${weightUnitLabel(widget.weightUnit)})',
                style: AppTextStyle.caption,
              ),
            ),
            SizedBox(width: 48),
          ],
        );
      case ExerciseInputType.repsOnly:
        return Row(
          children: [
            const SizedBox(width: 40),
            SizedBox(width: spacing.lg),
            Expanded(
              child: AppText(
                'Reps',
                style: AppTextStyle.caption,
              ),
            ),
            SizedBox(width: 48),
          ],
        );
      case ExerciseInputType.distanceAndTime:
        return Row(
          children: [
            const SizedBox(width: 40),
            SizedBox(width: spacing.lg),
            Expanded(
              child: AppText(
                'Distance (${distanceUnitLabel(widget.distanceUnit)})',
                style: AppTextStyle.caption,
              ),
            ),
            SizedBox(width: spacing.md),
            Expanded(
              child: AppText(
                'Time',
                style: AppTextStyle.caption,
              ),
            ),
            SizedBox(width: 48),
          ],
        );
      case ExerciseInputType.timeOnly:
        return Row(
          children: [
            const SizedBox(width: 40),
            SizedBox(width: spacing.lg),
            Expanded(
              child: AppText(
                'Time',
                style: AppTextStyle.caption,
              ),
            ),
            SizedBox(width: 48),
          ],
        );
    }
  }
}

class SetEditor extends StatefulWidget {
  final int setNumber;
  final dynamic set; // Can be WorkoutEntry or Map<String, dynamic>
  final ExerciseInputType inputType;
  final void Function(int reps, double weight, double? distance, int? duration) onChanged;
  final VoidCallback? onToggleComplete;
  final VoidCallback? onDelete;
  final WeightUnit weightUnit;
  final DistanceUnit distanceUnit;
  /// When true, the completion checkbox is hidden (e.g. for active card with "Complete Set" button).
  final bool hideCompleteCheckbox;

  const SetEditor({
    super.key,
    required this.setNumber,
    required this.set,
    required this.inputType,
    required this.onChanged,
    this.onToggleComplete,
    this.onDelete,
    this.weightUnit = WeightUnit.kg,
    this.distanceUnit = DistanceUnit.km,
    this.hideCompleteCheckbox = false,
  });

  @override
  State<SetEditor> createState() => SetEditorState();
}

class SetEditorState extends State<SetEditor> {
  late final TextEditingController _repsController;
  late final TextEditingController _weightController;
  late final TextEditingController _distanceController;
  late final TextEditingController _durationController;
  late final FocusNode _repsFocusNode;
  late final FocusNode _weightFocusNode;
  late final FocusNode _distanceFocusNode;
  late final FocusNode _durationFocusNode;

  bool get isLoggerSet => widget.set is Map<String, dynamic>;
  int get reps => isLoggerSet ? widget.set['reps'] ?? 0 : (widget.set as WorkoutEntry).reps;
  double get weight => isLoggerSet ? widget.set['weight'] ?? 0.0 : (widget.set as WorkoutEntry).weight;
  double? get distance => isLoggerSet 
      ? widget.set['distance'] != null ? (widget.set['distance'] as num).toDouble() : null
      : (widget.set as WorkoutEntry).distance;
  int? get duration => isLoggerSet 
      ? widget.set['duration'] != null ? widget.set['duration'] as int : null
      : (widget.set as WorkoutEntry).duration;
  bool get isComplete => isLoggerSet ? widget.set['isComplete'] ?? false : false;

  @override
  void initState() {
    super.initState();
    _repsController = TextEditingController(text: reps.toString());
    _weightController = TextEditingController(
      text: formatWeightValue(weight, unit: widget.weightUnit),
    );
    _distanceController = TextEditingController(
      text: distance != null
          ? formatDistanceValue(distance!, unit: widget.distanceUnit)
          : '',
    );
    _durationController = TextEditingController(
      text: duration != null ? formatDuration(duration!) : '',
    );
    _repsFocusNode = FocusNode();
    _weightFocusNode = FocusNode();
    _distanceFocusNode = FocusNode();
    _durationFocusNode = FocusNode();
    _repsFocusNode.addListener(_onFocusChange);
    _weightFocusNode.addListener(_onFocusChange);
    _distanceFocusNode.addListener(_onFocusChange);
    _durationFocusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant SetEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.set != oldWidget.set) {
      if (!_repsFocusNode.hasFocus) {
        _repsController.text = reps.toString();
      }
      if (!_weightFocusNode.hasFocus) {
        _weightController.text = formatWeightValue(weight, unit: widget.weightUnit);
      }
      if (!_distanceFocusNode.hasFocus) {
        _distanceController.text = distance != null
            ? formatDistanceValue(distance!, unit: widget.distanceUnit)
            : '';
      }
      if (!_durationFocusNode.hasFocus) {
        _durationController.text = duration != null ? formatDuration(duration!) : '';
      }
    }
  }

  @override
  void dispose() {
    _repsFocusNode.removeListener(_onFocusChange);
    _weightFocusNode.removeListener(_onFocusChange);
    _distanceFocusNode.removeListener(_onFocusChange);
    _durationFocusNode.removeListener(_onFocusChange);
    _repsController.dispose();
    _weightController.dispose();
    _distanceController.dispose();
    _durationController.dispose();
    _repsFocusNode.dispose();
    _weightFocusNode.dispose();
    _distanceFocusNode.dispose();
    _durationFocusNode.dispose();
    super.dispose();
  }

  bool get _isTimeValid {
    if (widget.inputType == ExerciseInputType.timeOnly || 
        widget.inputType == ExerciseInputType.distanceAndTime) {
      if (_durationController.text.isNotEmpty) {
        return isValidTime(_durationController.text);
      }
    }
    return true; // No time field, or time field is empty (will be validated on save)
  }

  void _onFocusChange() {
    setState(() {});
  }

  void _selectAll(TextEditingController controller) {
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
  }

  void _onChanged() {
    final reps = int.tryParse(_repsController.text) ?? 0;
    final weightInput = double.tryParse(_weightController.text) ?? 0.0;
    final weight = convertWeightToStorage(weightInput, widget.weightUnit);
    final distanceInput = _distanceController.text.isNotEmpty
        ? parseDistance(_distanceController.text)
        : null;
    final distance = distanceInput != null
        ? convertDistanceToStorage(distanceInput, widget.distanceUnit)
        : null;
    final duration = _durationController.text.isNotEmpty
        ? parseDuration(_durationController.text)
        : null;
    widget.onChanged(reps, weight, distance, duration);
    // Trigger rebuild to update checkbox state
    setState(() {});
  }

  InputDecoration _buildInputDecoration({
    required BuildContext context,
    String? hintText,
    required bool isFocused,
    bool showError = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    final borderColor = showError
        ? colors.error
        : (isFocused ? colors.primary : colors.outline);
    return InputDecoration(
      isDense: true,
      hintText: hintText,
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor, width: 1.5),
      ),
      hintStyle: TextStyle(
        color: colors.onSurface.withAlpha(128),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: isComplete
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Text(
              widget.setNumber.toString(),
              style: TextStyle(
                color: isComplete
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          ..._buildInputFields(context),
          const SizedBox(width: 8),
          if (!widget.hideCompleteCheckbox)
            Transform.scale(
              scale: 0.9,
              child: Checkbox(
                value: isComplete,
                onChanged: (_isTimeValid && widget.onToggleComplete != null)
                    ? (_) => widget.onToggleComplete!()
                    : null,
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildInputFields(BuildContext context) {
    switch (widget.inputType) {
      case ExerciseInputType.repsAndWeight:
        return [
          Expanded(
            child: TextField(
              controller: _repsController,
              focusNode: _repsFocusNode,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              decoration: _buildInputDecoration(
                context: context,
                isFocused: _repsFocusNode.hasFocus,
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              onChanged: (_) => _onChanged(),
              onTap: () => _selectAll(_repsController),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _weightController,
              focusNode: _weightFocusNode,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              decoration: _buildInputDecoration(
                context: context,
                isFocused: _weightFocusNode.hasFocus,
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              onChanged: (_) => _onChanged(),
              onTap: () => _selectAll(_weightController),
            ),
          ),
        ];
      case ExerciseInputType.repsOnly:
        return [
          Expanded(
            child: TextField(
              controller: _repsController,
              focusNode: _repsFocusNode,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              decoration: _buildInputDecoration(
                context: context,
                isFocused: _repsFocusNode.hasFocus,
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              onChanged: (_) => _onChanged(),
              onTap: () => _selectAll(_repsController),
            ),
          ),
        ];
      case ExerciseInputType.distanceAndTime:
        return [
          Expanded(
            child: TextField(
              controller: _distanceController,
              focusNode: _distanceFocusNode,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              decoration: _buildInputDecoration(
                context: context,
                isFocused: _distanceFocusNode.hasFocus,
                hintText: distanceUnitLabel(widget.distanceUnit),
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              onChanged: (_) => _onChanged(),
              onTap: () => _selectAll(_distanceController),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _durationController,
              focusNode: _durationFocusNode,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [TimeInputFormatter()],
              decoration: _buildInputDecoration(
                context: context,
                isFocused: _durationFocusNode.hasFocus,
                hintText: 'mm:ss',
                showError:
                    _durationController.text.isNotEmpty && !_isTimeValid,
              ),
              style: TextStyle(
                color: _durationController.text.isNotEmpty && !_isTimeValid
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.onSurface,
              ),
              onChanged: (_) => _onChanged(),
              onTap: () => _selectAll(_durationController),
            ),
          ),
        ];
      case ExerciseInputType.timeOnly:
        return [
          Expanded(
            child: TextField(
              controller: _durationController,
              focusNode: _durationFocusNode,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [TimeInputFormatter()],
              decoration: _buildInputDecoration(
                context: context,
                isFocused: _durationFocusNode.hasFocus,
                hintText: 'mm:ss',
                showError:
                    _durationController.text.isNotEmpty && !_isTimeValid,
              ),
              style: TextStyle(
                color: _durationController.text.isNotEmpty && !_isTimeValid
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.onSurface,
              ),
              onChanged: (_) => _onChanged(),
              onTap: () => _selectAll(_durationController),
            ),
          ),
        ];
    }
  }
} 