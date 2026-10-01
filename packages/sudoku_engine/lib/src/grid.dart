import 'dart:typed_data';

import 'tables.dart';

/// Mutable working board used by the solver and generator.
///
/// Keeps a used-digit mask per row, column and box so that
/// [candidates] is three loads and [set]/[clear] are O(1).
final class Grid {
  Grid();

  /// Builds a grid from 81 values (0 = empty).
  ///
  /// Returns `null` when the values break a row, column or box rule.
  static Grid? tryFrom(Uint8List source) {
    final g = Grid();
    for (var i = 0; i < 81; i++) {
      final d = source[i];
      if (d == 0) continue;
      if (g.candidates(i) & Tables.bitOf(d) == 0) return null;
      g.set(i, d);
    }
    return g;
  }

  /// Current values, 0 = empty.
  final Uint8List cells = Uint8List(81);
  final Int32List _rowUsed = Int32List(9);
  final Int32List _colUsed = Int32List(9);
  final Int32List _boxUsed = Int32List(9);

  /// Number of empty cells.
  int emptyCount = 81;

  /// Candidate mask for cell [i] given the digits already placed.
  int candidates(int i) {
    final t = Tables.instance;
    return ~(_rowUsed[t.rowOf[i]] |
            _colUsed[t.colOf[i]] |
            _boxUsed[t.boxOf[i]]) &
        Tables.kAll;
  }

  /// Places [digit] (1..9) in empty cell [i].
  void set(int i, int digit) {
    assert(cells[i] == 0, 'cell $i is not empty');
    final t = Tables.instance;
    final bit = 1 << (digit - 1);
    cells[i] = digit;
    _rowUsed[t.rowOf[i]] |= bit;
    _colUsed[t.colOf[i]] |= bit;
    _boxUsed[t.boxOf[i]] |= bit;
    emptyCount--;
  }

  /// Removes the digit in cell [i].
  void clear(int i) {
    final digit = cells[i];
    assert(digit != 0, 'cell $i is already empty');
    final t = Tables.instance;
    final bit = 1 << (digit - 1);
    cells[i] = 0;
    _rowUsed[t.rowOf[i]] &= ~bit;
    _colUsed[t.colOf[i]] &= ~bit;
    _boxUsed[t.boxOf[i]] &= ~bit;
    emptyCount++;
  }

  /// Deep copy.
  Grid clone() {
    final g = Grid();
    g.cells.setAll(0, cells);
    g._rowUsed.setAll(0, _rowUsed);
    g._colUsed.setAll(0, _colUsed);
    g._boxUsed.setAll(0, _boxUsed);
    g.emptyCount = emptyCount;
    return g;
  }
}
