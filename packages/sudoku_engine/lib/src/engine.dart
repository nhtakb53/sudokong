import 'dart:math';

import 'codec.dart';
import 'generator.dart';
import 'grid.dart';
import 'solver.dart';

/// Result of [SudokuEngine.solve].
final class SolveResult {
  const SolveResult({required this.solution, required this.solutionCount});

  /// The first solution found, or `null` when the puzzle has none.
  final String? solution;

  /// Number of solutions found, capped at the requested limit.
  final int solutionCount;

  bool get isUnique => solutionCount == 1;
}

/// Facade over the engine. All functions are pure and take or return only
/// strings, ints and small immutable result objects, so they can be called
/// directly inside `Isolate.run`.
abstract final class SudokuEngine {
  /// Generates a puzzle. Omit [seed] for a random one; pass the seed from a
  /// previous result to reproduce it.
  static GeneratedPuzzle generate({
    int? seed,
    GeneratorOptions options = const GeneratorOptions(),
  }) {
    final s = seed ?? Random().nextInt(1 << 31);
    return Generator(Random(s)).generate(options, s);
  }

  /// Solves [puzzle], counting up to [limit] solutions.
  ///
  /// Throws [CodecException] when the puzzle string is malformed.
  static SolveResult solve(String puzzle, {int limit = 2}) {
    final grid = Grid.tryFrom(GridCodec.parse(puzzle))!;
    final solver = Solver(grid);
    final count = solver.count(limit: limit);
    final first = solver.firstSolution;
    return SolveResult(
      solution: first == null ? null : GridCodec.format(first),
      solutionCount: count,
    );
  }

  /// Counts solutions of [puzzle], stopping at [limit].
  static int countSolutions(String puzzle, {int limit = 2}) {
    final grid = Grid.tryFrom(GridCodec.parse(puzzle))!;
    return Solver(grid).count(limit: limit);
  }

  /// Returns the first format problem with [puzzle], or `null` if valid.
  static CodecError? validate(String puzzle) => GridCodec.validate(puzzle);
}
