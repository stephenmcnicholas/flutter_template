import 'package:flutter/services.dart';
import 'package:fytter/src/domain/workout_entry.dart';
import 'package:fytter/src/domain/exercise_input_type.dart';

enum WeightUnit { kg, lb }
enum DistanceUnit { km, mi }

String weightUnitLabel(WeightUnit unit) => unit == WeightUnit.kg ? 'kg' : 'lb';
String distanceUnitLabel(DistanceUnit unit) => unit == DistanceUnit.km ? 'km' : 'mi';

double convertWeightToDisplay(double kg, WeightUnit unit) {
  if (unit == WeightUnit.kg) return kg;
  return kg * 2.20462;
}

double convertWeightToStorage(double value, WeightUnit unit) {
  if (unit == WeightUnit.kg) return value;
  return value / 2.20462;
}

double convertDistanceToDisplay(double km, DistanceUnit unit) {
  if (unit == DistanceUnit.km) return km;
  return km * 0.621371;
}

double convertDistanceToStorage(double value, DistanceUnit unit) {
  if (unit == DistanceUnit.km) return value;
  return value / 0.621371;
}

String formatWeight(double kg, {WeightUnit unit = WeightUnit.kg}) {
  final value = convertWeightToDisplay(kg, unit);
  return '${value.toStringAsFixed(1)} ${weightUnitLabel(unit)}';
}

String formatWeightValue(double kg, {WeightUnit unit = WeightUnit.kg}) {
  final value = convertWeightToDisplay(kg, unit);
  return value.toStringAsFixed(1);
}

String formatDistance(double km, {DistanceUnit unit = DistanceUnit.km}) {
  final value = convertDistanceToDisplay(km, unit);
  return '${value.toStringAsFixed(1)} ${distanceUnitLabel(unit)}';
}

String formatDistanceValue(double km, {DistanceUnit unit = DistanceUnit.km}) {
  final value = convertDistanceToDisplay(km, unit);
  return value.toStringAsFixed(1);
}

/// Formats a workout entry for display based on its input type.
String formatWorkoutEntryDisplay(
  WorkoutEntry entry,
  ExerciseInputType inputType, {
  WeightUnit weightUnit = WeightUnit.kg,
  DistanceUnit distanceUnit = DistanceUnit.km,
}) {
  switch (inputType) {
    case ExerciseInputType.repsAndWeight:
      return '${entry.reps} reps @ ${formatWeight(entry.weight, unit: weightUnit)}';
    case ExerciseInputType.repsOnly:
      return '${entry.reps} reps';
    case ExerciseInputType.distanceAndTime:
      final distanceStr = entry.distance != null
          ? formatDistance(entry.distance!, unit: distanceUnit)
          : '0.0 ${distanceUnitLabel(distanceUnit)}';
      final timeStr = entry.duration != null ? formatDuration(entry.duration!) : '0:00';
      return '$distanceStr in $timeStr';
    case ExerciseInputType.timeOnly:
      final timeStr = entry.duration != null ? formatDuration(entry.duration!) : '0:00';
      return timeStr;
  }
}

/// Formats duration in seconds to "mm:ss" or "hh:mm:ss" format.
/// Uses hh:mm:ss when hours > 0, otherwise uses mm:ss.
String formatDuration(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final secs = seconds % 60;
  
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  } else {
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}

/// Parses duration from "mm:ss", "m:ss", or "hh:mm:ss" format to seconds.
/// Returns 0 if parsing fails.
int parseDuration(String timeString) {
  try {
    final parts = timeString.split(':');
    if (parts.length == 2) {
      // mm:ss format
      final minutes = int.parse(parts[0]);
      final seconds = int.parse(parts[1]);
      if (minutes >= 0 && seconds >= 0 && seconds < 60) {
        return minutes * 60 + seconds;
      }
    } else if (parts.length == 3) {
      // hh:mm:ss format
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      final seconds = int.parse(parts[2]);
      if (hours >= 0 && minutes >= 0 && minutes < 60 && seconds >= 0 && seconds < 60) {
        return hours * 3600 + minutes * 60 + seconds;
      }
    }
  } catch (e) {
    // Invalid format, return 0
  }
  return 0;
}

/// Validates if a time string is valid (seconds and minutes must be < 60).
/// Returns true if valid, false otherwise.
bool isValidTime(String timeString) {
  try {
    final parts = timeString.split(':');
    if (parts.length == 2) {
      // mm:ss format
      final minutes = int.parse(parts[0]);
      final seconds = int.parse(parts[1]);
      return minutes >= 0 && seconds >= 0 && seconds < 60;
    } else if (parts.length == 3) {
      // hh:mm:ss format
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      final seconds = int.parse(parts[2]);
      return hours >= 0 && minutes >= 0 && minutes < 60 && seconds >= 0 && seconds < 60;
    }
  } catch (e) {
    // Invalid format
  }
  return false;
}


/// Parses distance from string (removes "km" suffix if present).
/// Returns 0.0 if parsing fails.
double parseDistance(String distanceString) {
  try {
    final cleaned = distanceString.replaceAll(RegExp(r'[^\d.]'), '');
    return double.parse(cleaned);
  } catch (e) {
    return 0.0;
  }
}

/// Text input formatter for time entry (mm:ss or hh:mm:ss format).
/// Formats input right-to-left: user types digits and they're formatted as seconds, then minutes, then hours.
/// Examples:
/// - "5" → "0:05"
/// - "45" → "0:45"
/// - "1000" → "10:00"
/// - "12345" → "1:23:45" (1 hour, 23 minutes, 45 seconds)
/// - "35959" → "3:59:59" (3 hours, 59 minutes, 59 seconds)
class TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // If text was deleted, allow deletion
    if (newValue.text.length < oldValue.text.length) {
      // If deleting the colon, remove the digit before it too
      if (oldValue.text.contains(':') && !newValue.text.contains(':')) {
        // User deleted the colon, remove the preceding digit
        final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
        if (digits.isEmpty) {
          return const TextEditingValue(text: '');
        }
        return _formatDigits(digits, newValue.selection);
      }
      // Normal deletion - format remaining digits
      final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
      if (digits.isEmpty) {
        return const TextEditingValue(text: '');
      }
      return _formatDigits(digits, newValue.selection);
    }

    // Extract only digits from input
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }

    return _formatDigits(digits, newValue.selection);
  }

  TextEditingValue _formatDigits(String digits, TextSelection selection) {
    // Format right-to-left: last 2 digits are seconds, next 2 are minutes, rest are hours
    // Do NOT clamp values - allow user to type freely, validation will check later
    String formatted;
    if (digits.length <= 2) {
      // Only seconds (0-99) - format as 0:XX
      final seconds = int.tryParse(digits) ?? 0;
      formatted = '0:${seconds.toString().padLeft(2, '0')}';
    } else if (digits.length <= 4) {
      // Has minutes and seconds (3-4 digits) - format as XX:XX (no hours)
      final secondsStr = digits.substring(digits.length - 2);
      final minutesStr = digits.substring(0, digits.length - 2);
      final seconds = int.tryParse(secondsStr) ?? 0;
      final minutes = int.tryParse(minutesStr) ?? 0;
      formatted = '$minutes:${seconds.toString().padLeft(2, '0')}';
    } else {
      // Has hours, minutes, and seconds (5+ digits) - format as XX:XX:XX
      // Last 2 digits = seconds, next 2 = minutes, rest = hours
      final secondsStr = digits.substring(digits.length - 2);
      final minutesStr = digits.substring(digits.length - 4, digits.length - 2);
      final hoursStr = digits.substring(0, digits.length - 4);
      final seconds = int.tryParse(secondsStr) ?? 0;
      final minutes = int.tryParse(minutesStr) ?? 0;
      final hours = int.tryParse(hoursStr) ?? 0;
      formatted = '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    // Place cursor at end for simplicity (common pattern for formatted input)
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
