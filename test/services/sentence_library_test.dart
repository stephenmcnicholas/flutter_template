import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/services/audio/sentence_library.dart';

void main() {
  // A controlled in-memory library covering all edge cases:
  //   s001 — has both mid and final variants
  //   s002 — has final variant only (tests fallback)
  //   s003 — no 'variants' key in JSON (tests default to ['mid'])
  late SentenceLibrary lib;

  setUp(() {
    lib = SentenceLibrary.fromJson({
      's001': {
        'text': 'Stand tall and brace your core.',
        'variants': ['mid', 'final'],
      },
      's002': {
        'text': 'Drive through your heels.',
        'variants': ['final'],
      },
      's003': {
        'text': 'Keep your chest up.',
        // no 'variants' key — should default to ['mid']
      },
    });
  });

  // -------------------------------------------------------------------------
  // getText
  // -------------------------------------------------------------------------

  group('getText', () {
    test('returns text for a known sentence id', () {
      expect(lib.getText('s001'), 'Stand tall and brace your core.');
      expect(lib.getText('s002'), 'Drive through your heels.');
    });

    test('returns empty string for an unknown id', () {
      expect(lib.getText('unknown'), '');
    });
  });

  // -------------------------------------------------------------------------
  // getClipId
  // -------------------------------------------------------------------------

  group('getClipId', () {
    test('formats as sentenceId_variant', () {
      expect(lib.getClipId('s001', 'mid'), 's001_mid');
      expect(lib.getClipId('s001', 'final'), 's001_final');
      expect(lib.getClipId('s002', 'final'), 's002_final');
    });
  });

  // -------------------------------------------------------------------------
  // getVariants
  // -------------------------------------------------------------------------

  group('getVariants', () {
    test('returns all variants for a known id', () {
      expect(lib.getVariants('s001'), ['mid', 'final']);
      expect(lib.getVariants('s002'), ['final']);
    });

    test('returns [mid] for an entry with no variants key', () {
      expect(lib.getVariants('s003'), ['mid']);
    });

    test('returns empty list for an unknown id', () {
      expect(lib.getVariants('unknown'), isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // hasVariant
  // -------------------------------------------------------------------------

  group('hasVariant', () {
    test('true when variant exists', () {
      expect(lib.hasVariant('s001', 'mid'), isTrue);
      expect(lib.hasVariant('s001', 'final'), isTrue);
      expect(lib.hasVariant('s002', 'final'), isTrue);
    });

    test('false when variant does not exist for a known id', () {
      expect(lib.hasVariant('s002', 'mid'), isFalse);
    });

    test('false for an unknown sentence id', () {
      expect(lib.hasVariant('unknown', 'mid'), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // pickVariant
  // -------------------------------------------------------------------------

  group('pickVariant', () {
    test('returns the wanted variant when it exists', () {
      expect(lib.pickVariant('s001', 'mid'), 'mid');
      expect(lib.pickVariant('s001', 'final'), 'final');
    });

    test('falls back to first available when wanted variant is missing', () {
      // s002 only has 'final'; asking for 'mid' should return 'final'
      expect(lib.pickVariant('s002', 'mid'), 'final');
    });

    test('returns mid when sentence id is unknown (no variants at all)', () {
      expect(lib.pickVariant('unknown', 'final'), 'mid');
    });

    test('s003 with no variants key defaults to mid', () {
      expect(lib.pickVariant('s003', 'mid'), 'mid');
      // asking for 'final' falls back to first available variant = 'mid'
      expect(lib.pickVariant('s003', 'final'), 'mid');
    });
  });

  // -------------------------------------------------------------------------
  // SentenceLibrary.empty()
  // -------------------------------------------------------------------------

  group('SentenceLibrary.empty()', () {
    test('getText returns empty string', () {
      expect(SentenceLibrary.empty().getText('s001'), '');
    });

    test('getVariants returns empty list', () {
      expect(SentenceLibrary.empty().getVariants('s001'), isEmpty);
    });

    test('pickVariant returns mid fallback', () {
      expect(SentenceLibrary.empty().pickVariant('s001', 'final'), 'mid');
    });
  });

  // -------------------------------------------------------------------------
  // fromJsonString round-trip
  // -------------------------------------------------------------------------

  test('fromJsonString parses the same data as fromJson', () {
    const jsonStr = '{'
        '"x001":{"text":"Hello.","variants":["mid","final"]},'
        '"x002":{"text":"World.","variants":["final"]}'
        '}';
    final parsed = SentenceLibrary.fromJsonString(jsonStr);
    expect(parsed.getText('x001'), 'Hello.');
    expect(parsed.getVariants('x002'), ['final']);
  });
}
