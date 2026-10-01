import 'package:sudoku_engine/src/singles_solver.dart';
import 'package:sudoku_engine/sudoku_engine.dart';
import 'package:test/test.dart';

void main() {
  const options = GeneratorOptions();

  test('same seed reproduces the same puzzle', () {
    final a = SudokuEngine.generate(seed: 42);
    final b = SudokuEngine.generate(seed: 42);
    expect(a.puzzle, b.puzzle);
    expect(a.solution, b.solution);
    expect(a.seed, 42);
  });

  test('different seeds give different puzzles', () {
    expect(
      SudokuEngine.generate(seed: 1).puzzle,
      isNot(SudokuEngine.generate(seed: 2).puzzle),
    );
  });

  test('generated puzzles are valid, unique, symmetric and singles-solvable',
      () {
    final watch = Stopwatch()..start();
    var maxMs = 0;
    for (var seed = 1; seed <= 20; seed++) {
      final one = Stopwatch()..start();
      final p = SudokuEngine.generate(seed: seed, options: options);
      one.stop();
      if (one.elapsedMilliseconds > maxMs) maxMs = one.elapsedMilliseconds;

      expect(GridCodec.validate(p.puzzle), isNull, reason: 'seed $seed');
      expect(p.givens, inInclusiveRange(options.minGivens - 1, options.maxGivens),
          reason: 'seed $seed');
      expect(p.puzzle.replaceAll('.', '').length, p.givens);

      final solve = SudokuEngine.solve(p.puzzle);
      expect(solve.isUnique, isTrue, reason: 'seed $seed');
      expect(solve.solution, p.solution, reason: 'seed $seed');

      for (var i = 0; i < 81; i++) {
        expect(p.puzzle[i] == '.', p.puzzle[80 - i] == '.',
            reason: 'seed $seed is not symmetric at $i');
      }

      final g = Grid.tryFrom(GridCodec.parse(p.puzzle))!;
      expect(SinglesSolver.run(g), SinglesOutcome.solved, reason: 'seed $seed');
    }
    watch.stop();
    // ignore: avoid_print
    print('generated 20 puzzles in ${watch.elapsedMilliseconds} ms '
        '(slowest ${maxMs} ms)');
    expect(maxMs, lessThan(5000));
  });

  test('uniqueness-only digging goes deeper', () {
    final p = SudokuEngine.generate(
      seed: 7,
      options: const GeneratorOptions(
        minGivens: 24,
        maxGivens: 30,
        requireSinglesSolvable: false,
      ),
    );
    expect(p.givens, lessThanOrEqualTo(30));
    expect(SudokuEngine.solve(p.puzzle).isUnique, isTrue);
  });
}
