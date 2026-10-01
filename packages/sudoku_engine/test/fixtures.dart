import 'dart:io';

/// Loads one puzzle per line from `test/fixtures/<name>.txt`.
List<String> loadFixture(String name) {
  final lines = File('test/fixtures/$name.txt').readAsLinesSync();
  return lines.map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
}

/// The Wikipedia example puzzle: solvable with singles only.
const kEasyPuzzle =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const kEasySolution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

/// [kEasySolution] with a deadly rectangle blanked (rows 4-5, columns 6 and
/// 9, digits 1 and 3), which leaves exactly two solutions.
String twoSolutionPuzzle() {
  final chars = kEasySolution.split('');
  for (final i in [3 * 9 + 5, 3 * 9 + 8, 4 * 9 + 5, 4 * 9 + 8]) {
    chars[i] = '.';
  }
  return chars.join();
}
