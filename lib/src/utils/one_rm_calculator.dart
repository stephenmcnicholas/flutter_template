/// Utility for calculating One-Rep Max (1RM) from weight and reps.
/// Uses the Epley formula: 1RM = weight × (1 + reps/30)
class OneRmCalculator {
  /// Calculate 1RM from weight and reps using Epley formula.
  /// Returns null if reps is 0 or weight is 0.
  static int? calculate(double weight, int reps) {
    if (reps <= 0 || weight <= 0) return null;
    if (reps == 1) return weight.round();
    
    // Epley formula: 1RM = weight × (1 + reps/30)
    final oneRm = weight * (1 + reps / 30);
    return oneRm.round();
  }
}

