import 'dart:math';
import 'dart:typed_data';

import 'codec.dart';
import 'grid.dart';
import 'singles_solver.dart';
import 'solver.dart';
import 'tables.dart';

/// Tuning knobs for [Generator].
final class GeneratorOptions {
  const GeneratorOptions({
    this.minGivens = 32,
    this.maxGivens = 36,
    this.requireSinglesSolvable = true,
    this.maxAttempts = 20,
  })  : assert(minGivens >= 17),
        assert(maxGivens >= minGivens),
        assert(maxAttempts >= 1);

  /// Never dig below this many givens.
  final int minGivens;

  /// A puzzle is accepted once it has at most this many givens.
  final int maxGivens;

  /// Keep only removals that leave the puzzle solvable with singles.
  /// When false, removals only need to keep the solution unique.
  final bool requireSinglesSolvable;

  /// Fresh grids to try before returning the best effort.
  final int maxAttempts;
}

/// A generated puzzle. Holds only strings and ints so it crosses isolates
/// cheaply.
final class GeneratedPuzzle {
  const GeneratedPuzzle({
    required this.puzzle,
    required this.solution,
    required this.givens,
    required this.seed,
  });

  /// 81 characters, `.` for empty cells.
  final String puzzle;

  /// 81 digits.
  final String solution;

  /// Number of given cells.
  final int givens;

  /// Seed that reproduces this puzzle with the same options.
  final int seed;

  @override
  String toString() => 'GeneratedPuzzle(givens: $givens, seed: $seed)';
}

/// Seedable puzzle generator: random full grid, then symmetric digging.
final class Generator {
  Generator(this._rng);

  final Random _rng;

  /// A random complete grid.
  Uint8List fullGrid() {
    final g = Grid();
    final filled = _fillRandom(g);
    assert(filled, 'an empty grid is always fillable');
    return Uint8List.fromList(g.cells);
  }

  /// Digs a puzzle out of a full grid using 180° rotational symmetry.
  GeneratedPuzzle generate(GeneratorOptions options, int seed) {
    GeneratedPuzzle? best;
    for (var attempt = 0; attempt < options.maxAttempts; attempt++) {
      final solution = fullGrid();
      final candidate = _dig(solution, options);
      if (candidate.givens <= options.maxGivens) {
        return _result(candidate, solution, seed);
      }
      if (best == null || candidate.givens < best.givens) {
        best = _result(candidate, solution, seed);
      }
    }
    return best!;
  }

  static GeneratedPuzzle _result(_Dug dug, Uint8List solution, int seed) {
    return GeneratedPuzzle(
      puzzle: GridCodec.format(dug.cells),
      solution: GridCodec.format(solution),
      givens: dug.givens,
      seed: seed,
    );
  }

  _Dug _dig(Uint8List solution, GeneratorOptions o) {
    final cells = Uint8List.fromList(solution);
    var givens = 81;
    final target = o.minGivens + _rng.nextInt(o.maxGivens - o.minGivens + 1);
    final pairs = List<int>.generate(41, (i) => i)..shuffle(_rng);

    for (final p in pairs) {
      if (givens <= target) break;
      final i = p;
      final j = 80 - p;
      final removed = i == j ? 1 : 2;
      if (givens - removed < o.minGivens) continue;

      final savedI = cells[i];
      final savedJ = cells[j];
      cells[i] = 0;
      cells[j] = 0;
      if (_accept(cells, o)) {
        givens -= removed;
      } else {
        cells[i] = savedI;
        cells[j] = savedJ;
      }
    }
    return _Dug(cells, givens);
  }

  static bool _accept(Uint8List cells, GeneratorOptions o) {
    final g = Grid.tryFrom(cells);
    if (g == null) return false;
    if (o.requireSinglesSolvable) {
      final outcome = SinglesSolver.run(g);
      assert(
        outcome != SinglesOutcome.solved || Solver(Grid.tryFrom(cells)!).count() == 1,
        'a singles-solvable puzzle must have exactly one solution',
      );
      return outcome == SinglesOutcome.solved;
    }
    return Solver(g).count() == 1;
  }

  /// Fills [g] completely with a random valid grid.
  bool _fillRandom(Grid g) {
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
    if (best == -1) return true;

    final digits = Uint8List(bestCount);
    var n = 0;
    for (var d = 1; d <= 9; d++) {
      if (bestMask & (1 << (d - 1)) != 0) digits[n++] = d;
    }
    for (var k = n - 1; k > 0; k--) {
      final r = _rng.nextInt(k + 1);
      final tmp = digits[k];
      digits[k] = digits[r];
      digits[r] = tmp;
    }
    for (var k = 0; k < n; k++) {
      g.set(best, digits[k]);
      if (_fillRandom(g)) return true;
      g.clear(best);
    }
    return false;
  }
}

final class _Dug {
  const _Dug(this.cells, this.givens);
  final Uint8List cells;
  final int givens;
}
