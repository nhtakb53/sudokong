import 'package:sudoku_engine/sudoku_engine.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  bool consistent(String puzzle, String solution) {
    for (var i = 0; i < 81; i++) {
      final p = puzzle[i];
      if (p != '.' && p != solution[i]) return false;
    }
    return GridCodec.validate(solution) == null && !solution.contains('.');
  }

  test('solves the easy puzzle to the known solution', () {
    final result = SudokuEngine.solve(kEasyPuzzle);
    expect(result.solution, kEasySolution);
    expect(result.isUnique, isTrue);
  });

  for (final name in ['top95', 'hardest']) {
    test('$name puzzles all have exactly one solution', () {
      final puzzles = loadFixture(name);
      final watch = Stopwatch()..start();
      for (final puzzle in puzzles) {
        final result = SudokuEngine.solve(puzzle);
        expect(result.solutionCount, 1, reason: puzzle);
        expect(consistent(puzzle, result.solution!), isTrue, reason: puzzle);
      }
      watch.stop();
      // ignore: avoid_print
      print('$name: ${puzzles.length} puzzles in ${watch.elapsedMilliseconds} ms');
    });
  }

  test('detects a puzzle with two solutions', () {
    final puzzle = twoSolutionPuzzle();
    expect(SudokuEngine.countSolutions(puzzle, limit: 10), 2);
    expect(SudokuEngine.solve(puzzle).isUnique, isFalse);
  });

  test('honours the limit', () {
    final empty = '.' * 81;
    expect(SudokuEngine.countSolutions(empty, limit: 1), 1);
    expect(SudokuEngine.countSolutions(empty, limit: 3), 3);
  });

  test('reports no solution for a contradictory puzzle', () {
    // Row 1 has 1-8 placed, and the 9 cannot go in the last cell because
    // its column already contains a 9.
    final rows = [
      '12345678.',
      '.........',
      '.........',
      '.........',
      '.........',
      '.........',
      '.........',
      '.........',
      '........9',
    ];
    final result = SudokuEngine.solve(rows.join());
    expect(result.solutionCount, 0);
    expect(result.solution, isNull);
  });
}
