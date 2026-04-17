/// Coerces JSON values that may be either a list (sentence-library format) or a
/// stray string (legacy / hand-edited files).
List<String> _sentenceIdsFromDynamic(dynamic raw) {
  if (raw == null) return const [];
  if (raw is List) return raw.map((e) => e.toString()).toList();
  if (raw is String) {
    final s = raw.trim();
    if (s.isEmpty) return const [];
    return [s];
  }
  return const [];
}

/// Coerces fields that must be JSON arrays but are sometimes stored as other types.
List<dynamic> _asDynamicList(dynamic value) {
  if (value == null) return const [];
  if (value is List) return value;
  return const [];
}

/// Ordered sentence IDs for a cue (setup, movement, good form, breathing) with
/// per-tier index lists. A null tier entry means the cue is omitted for that tier.
class ExerciseCueField {
  final List<String> sentences;
  final Map<String, List<int>?> tiers;

  const ExerciseCueField({
    required this.sentences,
    required this.tiers,
  });

  factory ExerciseCueField.fromJson(dynamic json) {
    if (json is! Map) {
      return const ExerciseCueField(sentences: [], tiers: {});
    }
    final m = Map<String, dynamic>.from(json);
    final sentences = _sentenceIdsFromDynamic(m['sentences']);
    final tiersRaw = m['tiers'] is Map
        ? Map<String, dynamic>.from(m['tiers'] as Map)
        : <String, dynamic>{};
    final tiers = <String, List<int>?>{};
    for (final key in const ['beginner', 'intermediate', 'advanced']) {
      final v = tiersRaw[key];
      if (v == null) {
        tiers[key] = null;
      } else if (v is List) {
        tiers[key] = v.map((e) => (e as num).toInt()).toList();
      }
    }
    return ExerciseCueField(sentences: sentences, tiers: tiers);
  }

  static const empty = ExerciseCueField(sentences: [], tiers: {});
}

/// Per-tier playback flags for a common fix (issue + fix sentence indices).
class ExerciseFixTier {
  final bool issue;
  final List<int> fix;

  const ExerciseFixTier({
    required this.issue,
    required this.fix,
  });

  factory ExerciseFixTier.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ExerciseFixTier(issue: false, fix: []);
    }
    final fixDyn = json['fix'];
    final fixRaw = fixDyn is List ? fixDyn : const <dynamic>[];
    return ExerciseFixTier(
      issue: json['issue'] as bool? ?? false,
      fix: fixRaw.map((e) => (e as num).toInt()).toList(),
    );
  }
}

/// Common mistake: issue sentence ID + fix sentence IDs + per-tier config.
class ExerciseCommonFix {
  final String issue;
  final List<String> fix;
  final Map<String, ExerciseFixTier> tiers;

  const ExerciseCommonFix({
    required this.issue,
    required this.fix,
    required this.tiers,
  });

  factory ExerciseCommonFix.fromJson(Map<String, dynamic> json) {
    final fixDyn = json['fix'];
    final List<String> fixList;
    if (fixDyn is List) {
      fixList = fixDyn.map((e) => e.toString()).toList();
    } else if (fixDyn is String && fixDyn.trim().isNotEmpty) {
      fixList = [fixDyn.trim()];
    } else {
      fixList = const [];
    }
    final tiersRaw = json['tiers'] is Map
        ? Map<String, dynamic>.from(json['tiers'] as Map)
        : <String, dynamic>{};
    final tiers = <String, ExerciseFixTier>{};
    for (final key in const ['beginner', 'intermediate', 'advanced']) {
      final m = tiersRaw[key];
      if (m is Map) {
        tiers[key] =
            ExerciseFixTier.fromJson(Map<String, dynamic>.from(m));
      }
    }
    return ExerciseCommonFix(
      issue: json['issue'] as String? ?? '',
      fix: fixList,
      tiers: tiers,
    );
  }
}

class ExerciseInstructionLink {
  final String name;
  final String description;
  final String? exerciseId;

  const ExerciseInstructionLink({
    required this.name,
    required this.description,
    this.exerciseId,
  });

  factory ExerciseInstructionLink.fromJson(Map<String, dynamic> json) {
    return ExerciseInstructionLink(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      exerciseId: json['exerciseId'] as String?,
    );
  }
}

class ExerciseInstructionLevelUp {
  final String description;
  final String? exerciseId;

  const ExerciseInstructionLevelUp({
    required this.description,
    this.exerciseId,
  });

  factory ExerciseInstructionLevelUp.fromJson(Map<String, dynamic> json) {
    return ExerciseInstructionLevelUp(
      description: json['description'] as String? ?? '',
      exerciseId: json['exerciseId'] as String?,
    );
  }
}

class ExerciseInstructions {
  final ExerciseCueField setup;
  final ExerciseCueField movement;
  final ExerciseCueField? goodFormFeels;
  final List<ExerciseCommonFix> commonFixes;
  final List<ExerciseInstructionLink> makeItEasier;
  final ExerciseInstructionLevelUp? levelUp;
  final ExerciseCueField? breathingCue;
  final String? safetyNote;

  const ExerciseInstructions({
    required this.setup,
    required this.movement,
    required this.commonFixes,
    required this.makeItEasier,
    this.goodFormFeels,
    this.levelUp,
    this.breathingCue,
    this.safetyNote,
  });

  factory ExerciseInstructions.fromJson(Map<String, dynamic> json) {
    return ExerciseInstructions(
      setup: ExerciseCueField.fromJson(json['setup']),
      movement: ExerciseCueField.fromJson(json['movement']),
      goodFormFeels: json['goodFormFeels'] == null
          ? null
          : ExerciseCueField.fromJson(json['goodFormFeels']),
      commonFixes: _asDynamicList(json['commonFixes'])
          .whereType<Map<String, dynamic>>()
          .map(ExerciseCommonFix.fromJson)
          .toList(),
      makeItEasier: _asDynamicList(json['makeItEasier'])
          .whereType<Map<String, dynamic>>()
          .map(ExerciseInstructionLink.fromJson)
          .toList(),
      levelUp: json['levelUp'] is Map<String, dynamic>
          ? ExerciseInstructionLevelUp.fromJson(
              json['levelUp'] as Map<String, dynamic>,
            )
          : null,
      breathingCue: json['breathingCue'] == null
          ? null
          : ExerciseCueField.fromJson(json['breathingCue']),
      safetyNote: json['safetyNote'] as String?,
    );
  }
}
