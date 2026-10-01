import 'dart:typed_data';

import 'package:sudoku_engine/sudoku_engine.dart';

/// Marks every cell whose digit also appears in one of its 20 peers.
///
/// This is a rule check only; it never looks at the solution.
Uint8List conflictsOf(Uint8List values) {
  final t = Tables.instance;
  final peers = t.peers;
  final out = Uint8List(81);
  for (var i = 0; i < 81; i++) {
    final v = values[i];
    if (v == 0) continue;
    final base = i * 20;
    for (var k = 0; k < 20; k++) {
      if (values[peers[base + k]] == v) {
        out[i] = 1;
        break;
      }
    }
  }
  return out;
}

/// True when every cell is filled and no rule is broken.
bool isSolved(Uint8List values) {
  for (var i = 0; i < 81; i++) {
    if (values[i] == 0) return false;
  }
  final conflicts = conflictsOf(values);
  for (var i = 0; i < 81; i++) {
    if (conflicts[i] != 0) return false;
  }
  return true;
}

/// Conjugate pairs of [digit]: the two cells of a unit that alone hold it
/// as a candidate. Each pair appears once, however many units share it.
List<(int, int)> conjugatePairs(Uint16List notes, int digit) {
  final t = Tables.instance;
  final bit = 1 << (digit - 1);
  final pairs = <(int, int)>[];
  for (var u = 0; u < 27; u++) {
    var a = -1;
    var b = -1;
    var count = 0;
    for (var k = 0; k < 9; k++) {
      final cell = t.units[u * 9 + k];
      if (notes[cell] & bit == 0) continue;
      count++;
      if (count == 1) {
        a = cell;
      } else if (count == 2) {
        b = cell;
      } else {
        break;
      }
    }
    if (count != 2) continue;
    final pair = a < b ? (a, b) : (b, a);
    if (!pairs.contains(pair)) pairs.add(pair);
  }
  return pairs;
}
