import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/utils/one_rm_calculator.dart';

void main() {
  group('OneRmCalculator', () {
    test('calculate returns correct 1RM for multiple reps using Epley formula', () {
      // Epley: 1RM = weight × (1 + reps/30)
      // 100kg × 5 reps = 100 × (1 + 5/30) = 100 × 1.1667 = 116.67 ≈ 117
      expect(OneRmCalculator.calculate(100.0, 5), 117);
      
      // 80kg × 10 reps = 80 × (1 + 10/30) = 80 × 1.333 = 106.67 ≈ 107
      expect(OneRmCalculator.calculate(80.0, 10), 107);
      
      // 50kg × 8 reps = 50 × (1 + 8/30) = 50 × 1.267 = 63.33 ≈ 63
      expect(OneRmCalculator.calculate(50.0, 8), 63);
    });

    test('calculate returns weight when reps is 1', () {
      expect(OneRmCalculator.calculate(100.0, 1), 100);
      expect(OneRmCalculator.calculate(50.5, 1), 51); // rounded
    });

    test('calculate returns null when reps is 0 or negative', () {
      expect(OneRmCalculator.calculate(100.0, 0), null);
      expect(OneRmCalculator.calculate(100.0, -1), null);
      expect(OneRmCalculator.calculate(100.0, -5), null);
    });

    test('calculate returns null when weight is 0 or negative', () {
      expect(OneRmCalculator.calculate(0.0, 5), null);
      expect(OneRmCalculator.calculate(-10.0, 5), null);
    });

    test('calculate rounds result correctly', () {
      // 100kg × 3 reps = 100 × (1 + 3/30) = 100 × 1.1 = 110.0
      expect(OneRmCalculator.calculate(100.0, 3), 110);
      
      // 33.33kg × 10 reps = 33.33 × (1 + 10/30) = 33.33 × 1.333 = 44.44 ≈ 44
      expect(OneRmCalculator.calculate(33.33, 10), 44);
    });
  });
}

