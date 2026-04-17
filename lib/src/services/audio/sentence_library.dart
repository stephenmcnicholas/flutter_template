import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Cached sentence catalog for Type B coaching: text for UI + variant metadata for clips.
class SentenceLibrary {
  SentenceLibrary._(this._byId);

  final Map<String, SentenceEntry> _byId;

  factory SentenceLibrary.empty() => SentenceLibrary._({});

  factory SentenceLibrary.fromJsonString(String jsonString) {
    final decoded = json.decode(jsonString) as Map<String, dynamic>;
    return SentenceLibrary.fromJson(decoded);
  }

  factory SentenceLibrary.fromJson(Map<String, dynamic> json) {
    final map = <String, SentenceEntry>{};
    for (final e in json.entries) {
      final id = e.key;
      final v = e.value;
      if (v is! Map<String, dynamic>) continue;
      map[id] = SentenceEntry.fromJson(v);
    }
    return SentenceLibrary._(map);
  }

  static Future<SentenceLibrary> loadFromAssets(AssetBundle bundle) async {
    final raw = await bundle.loadString('assets/exercises/sentences.json');
    return SentenceLibrary.fromJsonString(raw);
  }

  String getText(String sentenceId) => _byId[sentenceId]?.text ?? '';

  String getClipId(String sentenceId, String variant) => '${sentenceId}_$variant';

  List<String> getVariants(String sentenceId) {
    final v = _byId[sentenceId]?.variants ?? const [];
    return List<String>.from(v);
  }

  bool hasVariant(String sentenceId, String variant) =>
      getVariants(sentenceId).contains(variant);

  /// Picks [wanted] (`mid` or `final`) if present; otherwise first available variant.
  String pickVariant(String sentenceId, String wanted) {
    if (hasVariant(sentenceId, wanted)) return wanted;
    final v = getVariants(sentenceId);
    if (v.isEmpty) {
      if (kDebugMode) {
        debugPrint('[SentenceLibrary] No variants for $sentenceId — defaulting mid');
      }
      return 'mid';
    }
    return v.first;
  }
}

class SentenceEntry {
  const SentenceEntry({
    required this.text,
    required this.variants,
  });

  final String text;
  final List<String> variants;

  factory SentenceEntry.fromJson(Map<String, dynamic> json) {
    final v = json['variants'] as List<dynamic>? ?? const ['mid'];
    return SentenceEntry(
      text: json['text'] as String? ?? '',
      variants: v.map((e) => e.toString()).toList(),
    );
  }
}
