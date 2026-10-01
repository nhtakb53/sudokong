import 'grid.dart';
import 'tables.dart';

/// Result of running [SinglesSolver].
enum SinglesOutcome {
  /// Every cell was filled using singles only.
  solved,

  /// No contradiction, but singles alone cannot progress further.
  stuck,

  /// A cell or a digit ran out of places: the board is not solvable.
  contradiction,
}

/// Fills a board using only naked singles (a cell with one candidate) and
/// hidden singles (a digit with one place in a row, column or box).
///
/// This is the generator's internal "pleasant puzzle" check. It will grow
/// into the technique engine in a later phase.
abstract final class SinglesSolver {
  static SinglesOutcome run(Grid g) {
    final t = Tables.instance;
    final cells = g.cells;
    final units = t.units;
    final popcount = t.popcount;
    final lowestDigit = t.lowestDigit;

    var progress = true;
    while (progress) {
      progress = false;

      for (var i = 0; i < 81; i++) {
        if (cells[i] != 0) continue;
        final m = g.candidates(i);
        if (m == 0) return SinglesOutcome.contradiction;
        if (popcount[m] == 1) {
          g.set(i, lowestDigit[m]);
          progress = true;
        }
      }
      if (g.emptyCount == 0) return SinglesOutcome.solved;

      for (var u = 0; u < 27; u++) {
        final base = u * 9;
        var used = 0;
        for (var k = 0; k < 9; k++) {
          final d = cells[units[base + k]];
          if (d != 0) used |= 1 << (d - 1);
        }
        var missing = Tables.kAll & ~used;
        while (missing != 0) {
          final bit = missing & -missing;
          missing ^= bit;
          var where = -1;
          var places = 0;
          for (var k = 0; k < 9; k++) {
            final i = units[base + k];
            if (cells[i] != 0) continue;
            if (g.candidates(i) & bit != 0) {
              places++;
              where = i;
              if (places > 1) break;
            }
          }
          if (places == 0) return SinglesOutcome.contradiction;
          if (places == 1) {
            g.set(where, lowestDigit[bit]);
            progress = true;
          }
        }
      }
      if (g.emptyCount == 0) return SinglesOutcome.solved;
    }
    return SinglesOutcome.stuck;
  }
}
