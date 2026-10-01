import 'dart:typed_data';

/// Precomputed geometry and bit tables for a 9×9 sudoku.
///
/// Cells are indexed `i = row * 9 + col` (0..80). Digit `d` (1..9) maps to
/// bit `1 << (d - 1)`; a full candidate mask is [kAll].
final class Tables {
  Tables._() {
    for (var i = 0; i < 81; i++) {
      final r = i ~/ 9;
      final c = i % 9;
      rowOf[i] = r;
      colOf[i] = c;
      boxOf[i] = (r ~/ 3) * 3 + c ~/ 3;
    }
    // Units: rows 0-8, columns 9-17, boxes 18-26. Each unit lists 9 cells.
    for (var u = 0; u < 9; u++) {
      for (var k = 0; k < 9; k++) {
        units[u * 9 + k] = u * 9 + k;
        units[(9 + u) * 9 + k] = k * 9 + u;
        final br = (u ~/ 3) * 3 + k ~/ 3;
        final bc = (u % 3) * 3 + k % 3;
        units[(18 + u) * 9 + k] = br * 9 + bc;
      }
    }
    // Peers: the 20 cells sharing a row, column or box with each cell.
    for (var i = 0; i < 81; i++) {
      var n = 0;
      for (var j = 0; j < 81; j++) {
        if (j == i) continue;
        if (rowOf[j] == rowOf[i] ||
            colOf[j] == colOf[i] ||
            boxOf[j] == boxOf[i]) {
          peers[i * 20 + n] = j;
          n++;
        }
      }
      assert(n == 20, 'cell $i has $n peers');
    }
    // Bit tables for 9-bit masks.
    for (var m = 0; m < 512; m++) {
      var count = 0;
      var lowest = 0;
      for (var b = 0; b < 9; b++) {
        if (m & (1 << b) != 0) {
          count++;
          if (lowest == 0) lowest = b + 1;
        }
      }
      popcount[m] = count;
      lowestDigit[m] = lowest;
    }
  }

  /// The single shared instance. Capture it in a local before hot loops.
  static final Tables instance = Tables._();

  /// Mask with all nine candidate bits set.
  static const int kAll = 0x1FF;

  /// Row index (0..8) of each cell.
  final Uint8List rowOf = Uint8List(81);

  /// Column index (0..8) of each cell.
  final Uint8List colOf = Uint8List(81);

  /// Box index (0..8) of each cell.
  final Uint8List boxOf = Uint8List(81);

  /// 27 units × 9 cells, flattened: rows 0-8, columns 9-17, boxes 18-26.
  final Uint8List units = Uint8List(27 * 9);

  /// 81 cells × 20 peers, flattened.
  final Uint8List peers = Uint8List(81 * 20);

  /// Number of set bits for every 9-bit mask.
  final Uint8List popcount = Uint8List(512);

  /// Digit (1..9) of the lowest set bit for every 9-bit mask; 0 for mask 0.
  final Uint8List lowestDigit = Uint8List(512);

  /// Bit for [digit] (1..9).
  static int bitOf(int digit) => 1 << (digit - 1);
}
