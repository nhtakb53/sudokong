import 'package:sudoku_engine/src/singles_solver.dart';
import 'package:sudoku_engine/sudoku_engine.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  Grid gridOf(String puzzle) => Grid.tryFrom(GridCodec.parse(puzzle))!;

  test('solves the easy puzzle with singles only', () {
    final g = gridOf(kEasyPuzzle);
    expect(SinglesSolver.run(g), SinglesOutcome.solved);
    expect(GridCodec.format(g.cells), kEasySolution);
  });

  test('gets stuck on a hard puzzle', () {
    final g = gridOf(loadFixture('top95').first);
    expect(SinglesSolver.run(g), SinglesOutcome.stuck);
    expect(g.emptyCount, greaterThan(0));
  });

  test('reports a contradiction', () {
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
    final g = gridOf(rows.join());
    expect(SinglesSolver.run(g), SinglesOutcome.contradiction);
  });
}
