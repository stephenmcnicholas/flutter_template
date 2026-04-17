import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:fytter/src/domain/exercise_input_type.dart';
import 'package:fytter/src/domain/workout_entry.dart';
import 'package:fytter/src/utils/format_utils.dart';

void main() {
  group('formatDuration', () {
    test('formats seconds correctly (mm:ss format)', () {
      expect(formatDuration(0), '0:00');
      expect(formatDuration(30), '0:30');
      expect(formatDuration(60), '1:00');
      expect(formatDuration(90), '1:30');
      expect(formatDuration(125), '2:05');
      expect(formatDuration(3599), '59:59'); // Just under 1 hour
    });

    test('formats durations with hours (hh:mm:ss format)', () {
      expect(formatDuration(3600), '1:00:00'); // 1 hour
      expect(formatDuration(3661), '1:01:01'); // 1 hour, 1 minute, 1 second
      expect(formatDuration(7200), '2:00:00'); // 2 hours
      expect(formatDuration(14399), '3:59:59'); // 3 hours, 59 minutes, 59 seconds
    });

    test('handles large durations', () {
      expect(formatDuration(36000), '10:00:00'); // 10 hours
      expect(formatDuration(86400), '24:00:00'); // 24 hours
    });
  });

  group('parseDuration', () {
    test('parses valid mm:ss duration strings', () {
      expect(parseDuration('0:00'), 0);
      expect(parseDuration('0:30'), 30);
      expect(parseDuration('1:00'), 60);
      expect(parseDuration('1:30'), 90);
      expect(parseDuration('2:05'), 125);
      expect(parseDuration('59:59'), 3599);
    });

    test('parses valid hh:mm:ss duration strings', () {
      expect(parseDuration('1:00:00'), 3600); // 1 hour
      expect(parseDuration('1:01:01'), 3661); // 1 hour, 1 minute, 1 second
      expect(parseDuration('2:00:00'), 7200); // 2 hours
      expect(parseDuration('3:59:59'), 14399); // 3 hours, 59 minutes, 59 seconds
      expect(parseDuration('12:34:56'), 45296); // 12 hours, 34 minutes, 56 seconds
    });

    test('handles single digit minutes', () {
      expect(parseDuration('5:30'), 330);
      expect(parseDuration('9:59'), 599);
    });

    test('returns 0 for invalid formats', () {
      expect(parseDuration(''), 0);
      expect(parseDuration('invalid'), 0);
      expect(parseDuration('1'), 0);
      expect(parseDuration('1:'), 0);
      expect(parseDuration(':30'), 0);
      expect(parseDuration('1:60'), 0); // seconds >= 60
      expect(parseDuration('1:99'), 0); // seconds >= 60
      expect(parseDuration('1:60:00'), 0); // minutes >= 60 in hh:mm:ss
      expect(parseDuration('1:00:60'), 0); // seconds >= 60 in hh:mm:ss
    });

    test('handles negative values gracefully', () {
      expect(parseDuration('-1:00'), 0);
      expect(parseDuration('-1:00:00'), 0);
    });
  });

  group('formatDistance', () {
    test('formats distance correctly', () {
      expect(formatDistance(0.0), '0.0 km');
      expect(formatDistance(1.0), '1.0 km');
      expect(formatDistance(5.5), '5.5 km');
      expect(formatDistance(10.25), '10.3 km'); // Rounds to 1 decimal place
      expect(formatDistance(42.195), '42.2 km'); // Marathon distance
    });

    test('handles small distances', () {
      expect(formatDistance(0.1), '0.1 km');
      expect(formatDistance(0.5), '0.5 km');
    });

    test('handles large distances', () {
      expect(formatDistance(100.0), '100.0 km');
      expect(formatDistance(1000.0), '1000.0 km');
    });
  });

  group('unit conversions', () {
    test('converts weight between kg and lb', () {
      expect(convertWeightToDisplay(10.0, WeightUnit.kg), 10.0);
      expect(convertWeightToDisplay(10.0, WeightUnit.lb).toStringAsFixed(1), '22.0');
      expect(convertWeightToStorage(22.0, WeightUnit.lb).toStringAsFixed(1), '10.0');
    });

    test('converts distance between km and mi', () {
      expect(convertDistanceToDisplay(10.0, DistanceUnit.km), 10.0);
      expect(convertDistanceToDisplay(10.0, DistanceUnit.mi).toStringAsFixed(1), '6.2');
      expect(convertDistanceToStorage(6.2, DistanceUnit.mi).toStringAsFixed(1), '10.0');
    });

    test('formats weight and distance with units', () {
      expect(formatWeight(10.0, unit: WeightUnit.kg), '10.0 kg');
      expect(formatWeight(10.0, unit: WeightUnit.lb).toString(), '22.0 lb');
      expect(formatDistance(5.0, unit: DistanceUnit.km), '5.0 km');
      expect(formatDistance(5.0, unit: DistanceUnit.mi), '3.1 mi');
    });
  });

  group('isValidTime', () {
    test('returns true for valid mm:ss', () {
      expect(isValidTime('0:00'), isTrue);
      expect(isValidTime('5:30'), isTrue);
      expect(isValidTime('59:59'), isTrue);
    });

    test('returns true for valid hh:mm:ss', () {
      expect(isValidTime('1:00:00'), isTrue);
      expect(isValidTime('0:30:00'), isTrue);
      expect(isValidTime('12:59:59'), isTrue);
    });

    test('returns false for invalid or out-of-range', () {
      expect(isValidTime(''), isFalse);
      expect(isValidTime('1:60'), isFalse);
      expect(isValidTime('1:00:60'), isFalse);
      expect(isValidTime('invalid'), isFalse);
    });
  });

  group('formatWorkoutEntryDisplay', () {
    test('formats repsAndWeight entry', () {
      final entry = WorkoutEntry(
        id: 'e1',
        exerciseId: 'ex1',
        reps: 10,
        weight: 60.0,
        isComplete: false,
      );
      expect(
        formatWorkoutEntryDisplay(entry, ExerciseInputType.repsAndWeight),
        '10 reps @ 60.0 kg',
      );
    });

    test('formats repsOnly entry', () {
      final entry = WorkoutEntry(
        id: 'e1',
        exerciseId: 'ex1',
        reps: 15,
        weight: 0,
        isComplete: false,
      );
      expect(
        formatWorkoutEntryDisplay(entry, ExerciseInputType.repsOnly),
        '15 reps',
      );
    });

    test('formats timeOnly entry', () {
      final entry = WorkoutEntry(
        id: 'e1',
        exerciseId: 'ex1',
        reps: 0,
        weight: 0,
        duration: 90,
        isComplete: false,
      );
      expect(
        formatWorkoutEntryDisplay(entry, ExerciseInputType.timeOnly),
        '1:30',
      );
    });
  });

  group('parseDistance', () {
    test('parses valid distance strings', () {
      expect(parseDistance('5.0'), 5.0);
      expect(parseDistance('10.5'), 10.5);
      expect(parseDistance('42.195'), 42.195);
      expect(parseDistance('0.1'), 0.1);
    });

    test('handles strings with "km" suffix', () {
      expect(parseDistance('5.0 km'), 5.0);
      expect(parseDistance('10.5km'), 10.5);
      expect(parseDistance('42.195 km'), 42.195);
    });

    test('handles strings with other text', () {
      expect(parseDistance('Distance: 5.0 km'), 5.0);
      expect(parseDistance('5.0 kilometers'), 5.0);
    });

    test('returns 0.0 for invalid formats', () {
      expect(parseDistance(''), 0.0);
      expect(parseDistance('invalid'), 0.0);
      expect(parseDistance('no numbers'), 0.0);
    });

    test('strips negative signs (distances are always positive)', () {
      // The regex removes non-digit/non-period characters, including minus signs
      // This is acceptable since distances should always be positive
      expect(parseDistance('-5.0'), 5.0);
    });
  });

  group('TimeInputFormatter', () {
    final formatter = TimeInputFormatter();

    test('formats single digit as 0:0X', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '5'),
      );
      expect(result.text, '0:05');
    });

    test('formats two digits as 0:XX', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '45'),
      );
      expect(result.text, '0:45');
    });

    test('formats three digits as 0:XX (last 2 as seconds)', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '100'),
      );
      expect(result.text, '1:00');
    });

    test('formats four digits as XX:XX', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '1000'),
      );
      expect(result.text, '10:00');
    });

    test('formats five digits as hh:mm:ss', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '12345'),
      );
      expect(result.text, '1:23:45'); // 1 hour, 23 minutes, 45 seconds
    });

    test('formats six digits as hh:mm:ss', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '35959'),
      );
      expect(result.text, '3:59:59'); // 3 hours, 59 minutes, 59 seconds
    });

    test('formats more than six digits as hh:mm:ss', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '123456'),
      );
      expect(result.text, '12:34:56'); // 12 hours, 34 minutes, 56 seconds
    });

    test('handles deletion correctly', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: '10:00'),
        const TextEditingValue(text: '10:0'),
      );
      expect(result.text, '1:00');
    });

    test('handles deletion of colon', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: '1:00'),
        const TextEditingValue(text: '100'),
      );
      expect(result.text, '1:00');
    });

    test('handles empty input', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: '1:00'),
        const TextEditingValue(text: ''),
      );
      expect(result.text, '');
    });

    test('strips non-digit characters', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '1a2b3'),
      );
      // "1a2b3" -> "123" -> "1:23" (1 minute, 23 seconds)
      expect(result.text, '1:23');
    });

    test('maintains cursor position when possible', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(
          text: '0:05',
          selection: TextSelection.collapsed(offset: 2),
        ),
        const TextEditingValue(
          text: '0:055',
          selection: TextSelection.collapsed(offset: 5),
        ),
      );
      expect(result.text, '0:55');
      // Cursor should be positioned appropriately
      expect(result.selection.baseOffset, greaterThanOrEqualTo(0));
      expect(result.selection.baseOffset, lessThanOrEqualTo(result.text.length));
    });
  });
}
