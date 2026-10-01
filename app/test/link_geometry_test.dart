import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:sudokong/features/play/model/play_state.dart';
import 'package:sudokong/features/play/widgets/link_geometry.dart';

void main() {
  const size = Size(360, 388.8);

  NoteLink link(int a, int b) =>
      NoteLink(cellA: a, digitA: 5, cellB: b, digitB: 5, strong: true);

  test('links bow to one side, flipping only where they would leave', () {
    // Down column 1 the default bow points right, into the board: kept.
    final left = linkHandle(link(0, 72), size);
    expect(left.dx, greaterThan(noteCenter(0, 5, size).dx));
    // Down column 9 it would point right, off the board: flipped left.
    final right = linkHandle(link(8, 80), size);
    expect(right.dx, lessThan(noteCenter(8, 5, size).dx));
    expect(right.dx, lessThan(size.width));
    // Along row 9 leftwards the default bow points down, off the board.
    final bottom = linkHandle(link(80, 72), size);
    expect(bottom.dy, lessThan(noteCenter(72, 5, size).dy));
    expect(bottom.dy, lessThan(size.height));
    // The same link reversed bows up by default: nothing to flip.
    expect(linkHandle(link(72, 80), size).dy, bottom.dy);
    // A mid-board link keeps its default side, which depends on the way
    // it runs: left of travel, so a downward link bows left and an upward
    // one right.
    final down = linkHandle(link(4, 76), size);
    final up = linkHandle(link(76, 4), size);
    expect(down.dx, lessThan(noteCenter(4, 5, size).dx));
    expect(up.dx, greaterThan(noteCenter(4, 5, size).dx));
  });

  test('a link inside one cell is straight', () {
    final a = noteCenter(40, 1, size);
    final b = noteCenter(40, 9, size);
    final c = linkControl(a, b, size, sameCell: true);
    expect(c, Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2));
  });
}
