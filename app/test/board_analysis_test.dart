import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sudokong/features/play/model/board_analysis.dart';

void main() {
  test('conjugate pairs: units holding a digit in exactly two cells', () {
    final notes = Uint16List(81);
    const bit4 = 1 << 3;
    // 4 sits in r1c3, r2c2, r2c3, r5c2 and r5c6. Pairs: column 3 (r1c3,
    // r2c3), row 2 (r2c2, r2c3), column 2 (r2c2, r5c2), row 5 (r5c2, r5c6).
    // Box 1 holds three 4s, so it adds none.
    for (final cell in [2, 11, 10, 37, 41]) {
      notes[cell] |= bit4;
    }
    final pairs = conjugatePairs(notes, 4);
    expect(pairs, containsAll([(2, 11), (10, 11), (10, 37), (37, 41)]));
    expect(pairs.length, 4, reason: 'each pair once, none from the box');
    expect(conjugatePairs(notes, 5), isEmpty);
  });
}
