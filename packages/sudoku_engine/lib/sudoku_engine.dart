/// Pure Dart sudoku engine: board tables, codec, solver and generator.
///
/// Everything here is UI-agnostic and safe to run inside `Isolate.run`.
library;

export 'src/codec.dart';
export 'src/engine.dart';
export 'src/generator.dart' show GeneratedPuzzle, GeneratorOptions;
export 'src/grid.dart';
export 'src/tables.dart';
