import 'package:sudoku_engine/sudoku_engine.dart';
import 'package:test/test.dart';

void main() {
  final t = Tables.instance;

  test('every cell has 20 distinct peers that share a unit', () {
    for (var i = 0; i < 81; i++) {
      final peers = <int>{};
      for (var k = 0; k < 20; k++) {
        final j = t.peers[i * 20 + k];
        expect(j, isNot(i));
        expect(
          t.rowOf[j] == t.rowOf[i] ||
              t.colOf[j] == t.colOf[i] ||
              t.boxOf[j] == t.boxOf[i],
          isTrue,
        );
        peers.add(j);
      }
      expect(peers.length, 20);
    }
  });

  test('27 units each hold 9 distinct cells and cover the board 3 times', () {
    final coverage = List<int>.filled(81, 0);
    for (var u = 0; u < 27; u++) {
      final cells = <int>{};
      for (var k = 0; k < 9; k++) {
        final i = t.units[u * 9 + k];
        cells.add(i);
        coverage[i]++;
      }
      expect(cells.length, 9, reason: 'unit $u');
    }
    expect(coverage.every((c) => c == 3), isTrue);
  });

  test('box index matches row and column', () {
    expect(t.boxOf[0], 0);
    expect(t.boxOf[8], 2);
    expect(t.boxOf[40], 4);
    expect(t.boxOf[80], 8);
  });

  test('bit tables', () {
    expect(t.popcount[0], 0);
    expect(t.popcount[Tables.kAll], 9);
    expect(t.popcount[0x15], 3);
    expect(t.lowestDigit[0], 0);
    expect(t.lowestDigit[1], 1);
    expect(t.lowestDigit[0x100], 9);
    expect(t.lowestDigit[0x14], 3);
    expect(Tables.bitOf(1), 1);
    expect(Tables.bitOf(9), 0x100);
  });
}
