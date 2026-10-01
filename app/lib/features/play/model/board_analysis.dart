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
