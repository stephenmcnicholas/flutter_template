import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/data/exercise_seed_version.dart';

void main() {
  test('sha256HexOfUtf8 is stable for same input', () {
    const s = '{"a":1}';
    expect(sha256HexOfUtf8(s), sha256HexOfUtf8(s));
  });

  test('sha256HexOfUtf8 differs when content differs', () {
    expect(
      sha256HexOfUtf8('a'),
      isNot(equals(sha256HexOfUtf8('b'))),
    );
  });
}
