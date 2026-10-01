import 'package:sudoku_engine/sudoku_engine.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  test('round-trips fixtures', () {
    for (final line in loadFixture('top95')) {
      expect(GridCodec.format(GridCodec.parse(line)), line);
    }
  });

  test('reads 0 as empty and writes . by default', () {
    final zeros = kEasyPuzzle.replaceAll('.', '0');
    final cells = GridCodec.parse(zeros);
    expect(GridCodec.format(cells), kEasyPuzzle);
    expect(GridCodec.format(cells, empty: '0'), zeros);
  });

  test('rejects bad length', () {
    expect(GridCodec.validate('123'), CodecError.length);
    expect(() => GridCodec.parse('123'), throwsA(isA<CodecException>()));
  });

  test('rejects bad characters with the index', () {
    final bad = '${kEasyPuzzle.substring(0, 10)}x${kEasyPuzzle.substring(11)}';
    expect(GridCodec.validate(bad), CodecError.character);
    try {
      GridCodec.parse(bad);
      fail('should throw');
    } on CodecException catch (e) {
      expect(e.error, CodecError.character);
      expect(e.index, 10);
    }
  });

  test('rejects rule conflicts', () {
    // Two 5s in the first row.
    final bad = '55${kEasyPuzzle.substring(2)}';
    expect(GridCodec.validate(bad), CodecError.conflict);
  });

  test('accepts a valid puzzle', () {
    expect(GridCodec.validate(kEasyPuzzle), isNull);
  });
}
