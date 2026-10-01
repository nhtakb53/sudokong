import 'dart:typed_data';

import 'grid.dart';
import 'tables.dart';

/// Brute-force solver: bitmask backtracking with a fewest-candidates-first
/// cell choice. Counts solutions up to a limit, which makes uniqueness
/// checks cheap.
final class Solver {
  Solver(this.grid);

  /// The board being solved. It is left as it was found after [count].
  final Grid grid;

  int _limit = 2;
  int _count = 0;
  Uint8List? _first;

  /// First solution found by the last [count] call, or `null`.
  Uint8List? get firstSolution => _first;

  /// Counts solutions, stopping once [limit] are found.
  ///
  /// Returns `min(actual solutions, limit)`.
  int count({int limit = 2}) {
    _limit = limit;
    _count = 0;
    _first = null;
    if (limit <= 0) return 0;
    _search();
    return _count;
  }

  /// Returns `true` once the limit is reached.
  bool _search() {
    final g = grid;
    final cells = g.cells;
    final t = Tables.instance;
    final popcount = t.popcount;

    var best = -1;
    var bestMask = 0;
    var bestCount = 10;
    for (var i = 0; i < 81; i++) {
      if (cells[i] != 0) continue;
      final m = g.candidates(i);
      final c = popcount[m];
      if (c == 0) return false;
      if (c < bestCount) {
        best = i;
        bestMask = m;
        bestCount = c;
        if (c == 1) break;
      }
    }

    if (best == -1) {
      _count++;
      _first ??= Uint8List.fromList(cells);
      return _count >= _limit;
    }

    final lowestDigit = t.lowestDigit;
    var m = bestMask;
    while (m != 0) {
      final bit = m & -m;
      m ^= bit;
      g.set(best, lowestDigit[bit]);
      final done = _search();
      g.clear(best);
      if (done) return true;
    }
    return false;
  }
}
