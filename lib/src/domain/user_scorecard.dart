/// Internal user scorecard — 10 attributes scored 1.0–10.0.
/// Drives AI personalisation and rule engine behaviour.
/// Not surfaced to the user directly.
class UserScorecard {
  final String id;

  // Training
  final double consistency;
  final double progression;
  final double endurance;
  final double variety;

  // Knowledge
  final double fundamentals;
  final double selfAwareness;
  final double curiosity;

  // Mindset
  final double reliability;
  final double adaptability;
  final double independence;

  /// Computed level 1–5 (Beginner / Novice / Intermediate / Advanced / Self-coached).
  final int computedLevel;

  final DateTime? lastUpdated;

  const UserScorecard({
    required this.id,
    this.consistency = 5.0,
    this.progression = 3.0,
    this.endurance = 3.0,
    this.variety = 5.0,
    this.fundamentals = 1.0,
    this.selfAwareness = 5.0,
    this.curiosity = 5.0,
    this.reliability = 5.0,
    this.adaptability = 5.0,
    this.independence = 3.0,
    this.computedLevel = 1,
    this.lastUpdated,
  });

  /// All 10 attribute scores in order.
  List<double> get allScores => [
        consistency,
        progression,
        endurance,
        variety,
        fundamentals,
        selfAwareness,
        curiosity,
        reliability,
        adaptability,
        independence,
      ];

  /// Weighted average with Training slightly higher (1.2x).
  double get weightedAverage {
    const trainingWeight = 1.2;
    const otherWeight = 1.0;
    final weightedSum = (consistency + progression + endurance + variety) *
            trainingWeight +
        (fundamentals + selfAwareness + curiosity) * otherWeight +
        (reliability + adaptability + independence) * otherWeight;
    final totalWeight = 4 * trainingWeight + 3 * otherWeight + 3 * otherWeight;
    return weightedSum / totalWeight;
  }

  /// Three–five sentences for LLM / Cloud Function prompts (not shown in UI).
  String toNarrative() {
    final sentences = <String>[];
    final levelLabel = _levelLabel(computedLevel);

    if (consistency >= 7.0) {
      sentences.add('They usually show up and stick to their plan, so you can plan progression with reasonable confidence.');
    } else if (consistency <= 3.0) {
      sentences.add('They often miss sessions or struggle with routine—prioritise adherence and simple wins over aggressive volume or load.');
    }

    if (progression >= 7.0) {
      sentences.add('Load and volume have been trending up; they can tolerate a bit more challenge if recovery stays solid.');
    } else if (progression <= 2.0) {
      sentences.add('Progress has stalled; vary stimulus or trim volume before pushing intensity harder.');
    }

    if (endurance >= 7.0) {
      sentences.add('They tend to finish prescribed work and handle session length well.');
    } else if (endurance <= 3.0) {
      sentences.add('They may run out of steam before the session ends—keep density manageable and build work capacity gradually.');
    }

    if (variety <= 3.0) {
      sentences.add('Movement variety is low; rotate patterns slowly and explain why new exercises appear.');
    } else if (variety >= 8.0) {
      sentences.add('They already expose themselves to many patterns; you can keep selection focused rather than constantly novel.');
    }

    if (selfAwareness <= 3.0) {
      sentences.add('Their self-reported effort and outcomes do not always match reality—stay conservative with load jumps and verify with simple metrics.');
    } else if (selfAwareness >= 8.0) {
      sentences.add('They read their body well; you can use subtler autoregulation and trust their feedback more.');
    }

    if (fundamentals <= 3.0) {
      sentences.add('Foundational training literacy is still building—keep exercise choice and progression easy to follow.');
    } else if (fundamentals >= 7.0) {
      sentences.add('They understand training basics; you can use slightly richer structure or terminology.');
    }

    if (curiosity <= 3.0) {
      sentences.add('They rarely engage with extra coaching content; keep rationale short and actionable.');
    } else if (curiosity >= 8.0) {
      sentences.add('They engage with explanations; a bit more “why” behind choices will land well.');
    }

    if (reliability <= 3.0) {
      sentences.add('They often train later than scheduled slots suggest—avoid tying progression to rigid calendar assumptions.');
    } else if (reliability >= 7.0) {
      sentences.add('They tend to hit scheduled training days on time, so calendar-based structure should work.');
    }

    if (adaptability <= 3.0) {
      sentences.add('They resist sudden plan changes; preface adjustments with clear, short reasoning.');
    } else if (adaptability >= 7.0) {
      sentences.add('They adapt when plans shift; you can offer alternatives without over-explaining.');
    }

    if (independence >= 7.0) {
      sentences.add('They self-edit workouts sensibly and need less prescriptive micromanagement.');
    } else if (independence <= 2.0) {
      sentences.add('They prefer explicit structure—spell out sets, reps, and swaps rather than open-ended choices.');
    }

    if (sentences.isEmpty) {
      return 'They sit near the middle on most training traits. Use a standard progressive plan at $levelLabel level ($computedLevel/5) unless other user inputs contradict this.';
    }

    sentences.add('Coaching band: $levelLabel ($computedLevel/5)—match complexity and touchpoints to that level.');
    return sentences.join(' ');
  }

  static String _levelLabel(int level) {
    switch (level) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Novice';
      case 3:
        return 'Intermediate';
      case 4:
        return 'Advanced';
      case 5:
        return 'Self-coached';
      default:
        return 'Beginner';
    }
  }

  UserScorecard copyWith({
    String? id,
    double? consistency,
    double? progression,
    double? endurance,
    double? variety,
    double? fundamentals,
    double? selfAwareness,
    double? curiosity,
    double? reliability,
    double? adaptability,
    double? independence,
    int? computedLevel,
    DateTime? lastUpdated,
  }) {
    return UserScorecard(
      id: id ?? this.id,
      consistency: consistency ?? this.consistency,
      progression: progression ?? this.progression,
      endurance: endurance ?? this.endurance,
      variety: variety ?? this.variety,
      fundamentals: fundamentals ?? this.fundamentals,
      selfAwareness: selfAwareness ?? this.selfAwareness,
      curiosity: curiosity ?? this.curiosity,
      reliability: reliability ?? this.reliability,
      adaptability: adaptability ?? this.adaptability,
      independence: independence ?? this.independence,
      computedLevel: computedLevel ?? this.computedLevel,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserScorecard &&
        other.id == id &&
        other.consistency == consistency &&
        other.progression == progression &&
        other.endurance == endurance &&
        other.variety == variety &&
        other.fundamentals == fundamentals &&
        other.selfAwareness == selfAwareness &&
        other.curiosity == curiosity &&
        other.reliability == reliability &&
        other.adaptability == adaptability &&
        other.independence == independence &&
        other.computedLevel == computedLevel &&
        other.lastUpdated == lastUpdated;
  }

  @override
  int get hashCode => Object.hash(
        id,
        consistency,
        progression,
        endurance,
        variety,
        fundamentals,
        selfAwareness,
        curiosity,
        reliability,
        adaptability,
        independence,
        computedLevel,
        lastUpdated,
      );
}
