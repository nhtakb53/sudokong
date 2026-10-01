import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sudokong/features/play/model/play_intent.dart';
import 'package:sudokong/features/play/model/play_reducer.dart';
import 'package:sudokong/features/play/model/play_state.dart';
import 'package:sudokong/features/play/model/saved_game_codec.dart';
import 'package:sudoku_engine/sudoku_engine.dart';

const _puzzle =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

void main() {
  PlayState played() {
    var s = PlayState.fromPuzzle(
      const GeneratedPuzzle(
        puzzle: _puzzle,
        solution: _solution,
        givens: 30,
        seed: 42,
      ),
    );
    s = reduce(s, const FillCandidates());
    s = reduce(s, const SelectCell(2));
    s = reduce(s, const EnterDigit(4));
    s = reduce(s, const PickPaint(3));
    s = reduce(s, const PaintCell(10));
    s = reduce(s, const PaintNote(11, 7));
    s = reduce(s, const ToggleLinkTool());
    s = reduce(s, const TapForLink(10, 7));
    s = reduce(s, const TapForLink(11, 7));
    s = reduce(s, const ToggleLinkType(0));
    return s;
  }

  test('a game round-trips with marks, paint, links and the clock', () {
    final s = played();
    final raw = SavedGameCodec.encodeString(s, 754);
    final back = SavedGameCodec.decodeString(raw);
    expect(back, isNotNull);
    expect(back!.seconds, 754);
    final r = back.state;
    expect(r.givens, s.givens);
    expect(r.solution, s.solution);
    expect(r.values, s.values);
    expect(r.notes, s.notes);
    expect(r.cellColors, s.cellColors);
    expect(r.noteColors, s.noteColors);
    expect(r.seed, 42);
    expect(r.links.length, 1);
    expect(r.links.single.cellA, 10);
    expect(r.links.single.digitA, 7);
    expect(r.links.single.cellB, 11);
    expect(r.links.single.strong, s.links.single.strong);
    expect(r.links.single.manual, isTrue);
    expect(r.completed, isFalse);
    expect(r.hasProgress, isTrue);
    expect(r.undoStack, isEmpty, reason: 'history is not kept');
  });

  test('broken or foreign data yields nothing', () {
    expect(SavedGameCodec.decodeString(null), isNull);
    expect(SavedGameCodec.decodeString(''), isNull);
    expect(SavedGameCodec.decodeString('not json'), isNull);
    expect(SavedGameCodec.decodeString('[1]'), isNull);
    expect(SavedGameCodec.decodeString('{"v":99}'), isNull);
    expect(SavedGameCodec.decodeString('{"v":1,"puzzle":"x"}'), isNull);
  });

  test('a fresh board has no progress; a completed one neither', () {
    final s = PlayState.fromPuzzle(
      const GeneratedPuzzle(
        puzzle: _puzzle,
        solution: _solution,
        givens: 30,
        seed: 1,
      ),
    );
    expect(s.hasProgress, isFalse);
    final done = s.copyWith(
      values: Uint8List.fromList(GridCodec.parse(_solution)),
      completed: true,
    );
    expect(done.hasProgress, isFalse);
  });
}
