import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sudokong/features/play/model/board_analysis.dart';
import 'package:sudokong/features/play/model/play_intent.dart';
import 'package:sudokong/features/play/model/play_reducer.dart';
import 'package:sudokong/features/play/model/play_state.dart';
import 'package:sudokong/features/settings/app_settings.dart';
import 'package:sudoku_engine/sudoku_engine.dart';

const _puzzle =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

void main() {
  PlayState fresh() => PlayState.fromPuzzle(
    const GeneratedPuzzle(
      puzzle: _puzzle,
      solution: _solution,
      givens: 30,
      seed: 1,
    ),
  );

  test('selecting a cell', () {
    final s = reduce(fresh(), const SelectCell(2));
    expect(s.selected, 2);
    expect(identical(reduce(s, const SelectCell(2)), s), isTrue);
  });

  test('entering a digit into an empty cell, then toggling it off', () {
    var s = reduce(fresh(), const SelectCell(2));
    s = reduce(s, const EnterDigit(4));
    expect(s.values[2], 4);
    s = reduce(s, const EnterDigit(4));
    expect(s.values[2], 0);
  });

  test('givens are locked', () {
    final start = reduce(fresh(), const SelectCell(0));
    final s = reduce(start, const EnterDigit(9));
    expect(s.values, start.values);
    expect(s.values[0], 5);
    expect(s.activeDigit, 9);
  });

  test('a digit key without a selection only changes the highlight', () {
    final start = fresh();
    final s = reduce(start, const EnterDigit(1));
    expect(s.values, start.values);
    expect(s.activeDigit, 1);
    expect(identical(reduce(s, const EnterDigit(1)), s), isTrue);
  });

  test('fill candidates and clear them as digits are placed', () {
    var s = reduce(fresh(), const FillCandidates());
    // r1c3 (index 2): row 1 has 5,3,7; col 3 has 8; box 1 has 5,3,6,9,8 -> 1,2,4.
    expect(s.notes[2], (1 << 0) | (1 << 1) | (1 << 3));
    // Givens keep no notes.
    expect(s.notes[0], 0);
    // r1c4 (index 3): row 1 has 5,3,7; col 4 has 1,8,4; box 2 has 7,1,9,5 -> 2 or 6.
    expect(s.notes[3], (1 << 1) | (1 << 5));
    // r1c6 (index 5) allows 1,2,4,6,8 before anything is placed.
    expect(s.notes[5] & (1 << 3), isNot(0));
    s = reduce(s, const SelectCell(2));
    s = reduce(s, const EnterDigit(4));
    expect(s.notes[2], 0);
    // Placing 4 at r1c3 removes 4 from its row peer r1c6 but keeps its 2.
    expect(s.notes[5] & (1 << 3), 0);
    expect(s.notes[5] & (1 << 1), isNot(0));
  });

  test('conflicts are rule based', () {
    var s = reduce(fresh(), const SelectCell(2));
    s = reduce(s, const EnterDigit(5)); // 5 already in row 1
    final c = conflictsOf(s.values);
    expect(c[2], 1);
    expect(c[0], 1);
    expect(isSolved(s.values), isFalse);
  });

  test(
    'digit keys pick the highlighted digit even without a writable cell',
    () {
      final start = fresh();
      var s = reduce(start, const EnterDigit(7));
      expect(s.activeDigit, 7);
      expect(s.highlightOrder, [7]);
      s = reduce(s, const SelectCell(0)); // given 5
      expect(s.highlightOrder, [5]);
      s = reduce(
        s,
        const EnterDigit(3),
      ); // given stays, highlight follows the key
      expect(s.values[0], 5);
      expect(s.activeDigit, 3);
      expect(s.highlightOrder, [3], reason: 'the last key pressed wins');
      s = reduce(s, const SelectCell(2)); // empty cell
      expect(s.highlightOrder, isEmpty);
      s = reduce(s, const EnterDigit(4));
      expect(s.values[2], 4);
      expect(s.highlightOrder, [4]);
    },
  );

  test('clearing the selection drops the cell and the highlight', () {
    var s = reduce(fresh(), const SelectCell(0));
    s = reduce(s, const EnterDigit(7));
    s = reduce(s, const ClearSelection());
    expect(s.selected, isNull);
    expect(s.activeDigit, 0);
    expect(s.highlightOrder, isEmpty);
    expect(identical(reduce(s, const ClearSelection()), s), isTrue);
  });

  group('multi-digit highlight', () {
    test('held keys build a set, oldest first, that cell taps keep', () {
      var s = reduce(fresh(), const HoldDigit(3));
      expect(s.highlightOrder, [3]);
      expect(s.activeDigit, 3);
      s = reduce(s, const HoldDigit(7));
      expect(s.highlightOrder, [3, 7]);
      expect(s.activeDigit, 7, reason: 'the digit touched last is active');
      s = reduce(s, const SelectCell(0)); // given 5
      expect(s.highlightOrder, [3, 7], reason: 'a hand-built set stays');
      expect(s.activeDigit, 5);
      s = reduce(s, const SelectCell(2)); // empty
      expect(s.highlightOrder, [3, 7]);
      // A key tap means one digit again.
      s = reduce(s, const SelectCell(0));
      s = reduce(s, const EnterDigit(4));
      expect(s.highlightOrder, [4]);
      expect(s.activeDigit, 4);
    });

    test('all nine digits get their own slot; slots stay put', () {
      var s = fresh();
      for (var d = 1; d <= 9; d++) {
        s = reduce(s, ToggleHighlight(d));
      }
      expect(s.highlightOrder, [1, 2, 3, 4, 5, 6, 7, 8, 9]);
      for (var d = 1; d <= 9; d++) {
        expect(s.slotOf(d), d - 1);
      }
      expect(s.activeDigit, 9);
      s = reduce(s, const ToggleHighlight(3));
      expect(s.highlightOrder, [1, 2, 4, 5, 6, 7, 8, 9]);
      expect(s.slotOf(4), 3, reason: 'removing 3 recolors nobody');
      expect(s.slotOf(9), 8);
      s = reduce(s, const ToggleHighlight(3)); // comes back into the gap
      expect(s.slotOf(3), 2);
      expect(s.activeDigit, 3);
      s = reduce(s, const ToggleHighlight(3)); // the active one leaves
      expect(s.activeDigit, 9, reason: 'hands over to the newest digit');
      expect(s.undoStack, isEmpty, reason: 'highlights are not undoable');
    });

    test('down to one digit the highlight is the standard blue again', () {
      var s = fresh();
      for (final d in [2, 4, 5]) {
        s = reduce(s, ToggleHighlight(d));
      }
      s = reduce(s, const ToggleHighlight(2));
      expect(s.highlightOrder, [4, 5]);
      expect(s.slotOf(4), 1, reason: 'still amber while two are lit');
      s = reduce(s, const ToggleHighlight(5));
      expect(s.highlightOrder, [4]);
      expect(s.slotOf(4), 0);
      expect(s.activeDigit, 4);
      s = reduce(s, const ToggleHighlight(4));
      expect(s.highlightOrder, isEmpty);
      expect(s.activeDigit, 0);
    });

    test(
      'a hold writes into a writable cell (cell-first) and keeps the set',
      () {
        var s = reduce(fresh(), const HoldDigit(3));
        s = reduce(s, const HoldDigit(7));
        s = reduce(s, const SelectCell(2)); // empty r1c3
        s = reduce(s, const HoldDigit(4));
        expect(s.values[2], 4);
        expect(s.highlightOrder, [3, 7]);
        // On a given cell it toggles instead.
        s = reduce(s, const SelectCell(0));
        s = reduce(s, const HoldDigit(9));
        expect(s.values[0], 5);
        expect(s.highlightOrder, [3, 7, 9]);
      },
    );

    test('digit-first: a hold never writes and never arms', () {
      const mode = InputMode.digitFirst;
      var s = reduce(fresh(), const HoldDigit(3), inputMode: mode);
      s = reduce(s, const HoldDigit(7), inputMode: mode);
      expect(s.highlightOrder, [3, 7]);
      expect(s.activeDigit, 0, reason: 'a highlight must not arm a digit');
      s = reduce(s, const SelectCell(2), inputMode: mode); // only selects
      expect(s.values[2], 0);
      expect(s.notes[2], 0);
      s = reduce(s, const EnterDigit(7), inputMode: mode); // arm 7
      expect(s.highlightOrder, [3, 7], reason: 'arming keeps the set');
      s = reduce(s, const SelectCell(2), inputMode: mode); // places 7
      expect(s.values[2], 7);
      s = reduce(s, const HoldDigit(1), inputMode: mode);
      expect(s.highlightOrder, [3, 7, 1]);
      expect(s.activeDigit, 7, reason: 'the hold leaves the armed digit');
      s = reduce(s, const ToggleNoteMode(), inputMode: mode);
      s = reduce(s, const HoldDigit(4), inputMode: mode);
      s = reduce(s, const SelectCell(3), inputMode: mode); // empty r1c4
      expect(s.notes[3] & (1 << 3), 0, reason: '4 was never armed');
      expect(s.notes[3] & (1 << 6), isNot(0), reason: '7 still is');
    });

    test('a lone held highlight is pinned: cell taps keep it', () {
      for (final mode in InputMode.values) {
        var s = reduce(fresh(), const HoldDigit(5), inputMode: mode);
        expect(s.highlightOrder, [5]);
        expect(s.highlightPinned, isTrue);
        s = reduce(s, const SelectCell(2), inputMode: mode); // empty cell
        expect(s.highlightOrder, [5], reason: '$mode: empty tap keeps it');
        s = reduce(s, const SelectCell(0), inputMode: mode); // given 5
        s = reduce(s, const SelectCell(1), inputMode: mode); // given 3
        expect(s.highlightOrder, [5], reason: '$mode: given tap keeps it');
        s = reduce(s, const ClearSelection(), inputMode: mode);
        expect(s.highlightOrder, isEmpty);
        expect(s.highlightPinned, isFalse);
      }
    });

    test('a key tap replaces a pinned highlight with a plain one', () {
      var s = reduce(fresh(), const HoldDigit(5));
      s = reduce(s, const EnterDigit(5)); // same key, nothing to write
      expect(s.highlightOrder, [5]);
      expect(s.highlightPinned, isFalse);
      s = reduce(s, const SelectCell(2)); // empty: plain highlight follows
      expect(s.highlightOrder, isEmpty);
    });

    test('clearing the selection drops the whole set', () {
      var s = reduce(fresh(), const HoldDigit(3));
      s = reduce(s, const HoldDigit(7));
      s = reduce(s, const ClearSelection());
      expect(s.highlightOrder, isEmpty);
      expect(s.activeDigit, 0);
    });
  });

  group('digit-first input', () {
    const mode = InputMode.digitFirst;

    test('a key arms the digit, taps place it, the same key disarms', () {
      var s = reduce(fresh(), const EnterDigit(4), inputMode: mode);
      expect(s.activeDigit, 4);
      s = reduce(s, const SelectCell(2), inputMode: mode); // empty r1c3
      expect(s.values[2], 4);
      expect(s.selected, 2);
      expect(s.activeDigit, 4, reason: 'digit stays armed');
      s = reduce(s, const SelectCell(2), inputMode: mode); // same cell again
      expect(s.values[2], 0, reason: 'tapping again clears it');
      s = reduce(s, const EnterDigit(4), inputMode: mode);
      expect(s.activeDigit, 0, reason: 'pressing the armed key disarms');
    });

    test('a given cell is never overwritten; it switches the armed digit', () {
      var s = reduce(fresh(), const EnterDigit(4), inputMode: mode);
      s = reduce(s, const SelectCell(0), inputMode: mode); // given 5
      expect(s.values[0], 5);
      expect(s.activeDigit, 5);
    });

    test('without an armed digit taps just select', () {
      final s = reduce(fresh(), const SelectCell(2), inputMode: mode);
      expect(s.selected, 2);
      expect(s.values[2], 0);
    });
  });

  test('note mode toggles pencil marks and long-press still writes', () {
    var s = reduce(fresh(), const ToggleNoteMode());
    expect(s.noteMode, isTrue);
    s = reduce(s, const SelectCell(2)); // empty r1c3
    s = reduce(s, const EnterNote(4));
    expect(s.notes[2] & (1 << 3), isNot(0));
    expect(s.values[2], 0);
    expect(s.highlightOrder, [4]);
    s = reduce(s, const EnterNote(4));
    expect(s.notes[2] & (1 << 3), 0, reason: 'second tap removes the mark');
    // The forced value entry ignores note mode.
    s = reduce(s, const EnterDigit(4));
    expect(s.values[2], 4);
    expect(s.noteMode, isTrue, reason: 'mode is not changed by a write');
  });

  test('notes never land on a filled cell', () {
    var s = reduce(fresh(), const SelectCell(0)); // given 5
    s = reduce(s, const EnterNote(3));
    expect(s.notes[0], 0);
    expect(s.activeDigit, 3);
  });

  test('digit-first with note mode writes marks; long-press places', () {
    const mode = InputMode.digitFirst;
    var s = reduce(fresh(), const ToggleNoteMode(), inputMode: mode);
    s = reduce(s, const EnterDigit(4), inputMode: mode); // arm 4
    s = reduce(s, const SelectCell(2), inputMode: mode);
    expect(s.notes[2] & (1 << 3), isNot(0));
    expect(s.values[2], 0);
    s = reduce(s, const PlaceAt(2), inputMode: mode);
    expect(s.values[2], 4);
    expect(s.notes[2], 0);
  });

  test('erase clears the value first, then the marks', () {
    var s = reduce(fresh(), const SelectCell(2));
    s = reduce(s, const EnterNote(1));
    s = reduce(s, const EnterNote(2));
    s = reduce(s, const EnterDigit(4)); // value on top of marks
    expect(s.values[2], 4);
    s = reduce(s, const Erase());
    expect(s.values[2], 0);
    s = reduce(s, const EnterNote(1));
    s = reduce(s, const Erase());
    expect(s.notes[2], 0);
    expect(identical(reduce(s, const Erase()), s), isTrue);
  });

  test('undo walks back through every board change', () {
    final start = fresh();
    var s = reduce(start, const SelectCell(2));
    expect(s.canUndo, isFalse, reason: 'selection is not a board change');
    s = reduce(s, const EnterDigit(4));
    s = reduce(s, const EnterNote(7)); // ignored: cell has a value
    s = reduce(s, const FillCandidates());
    expect(s.undoStack.length, 2);
    s = reduce(s, const Undo());
    expect(s.notes.every((n) => n == 0), isTrue);
    expect(s.values[2], 4);
    s = reduce(s, const Undo());
    expect(s.values[2], 0);
    expect(s.canUndo, isFalse);
    expect(identical(reduce(s, const Undo()), s), isTrue);
  });

  test('redo re-applies undone changes until a new change happens', () {
    var s = reduce(fresh(), const SelectCell(2));
    s = reduce(s, const EnterDigit(4));
    s = reduce(s, const Undo());
    expect(s.values[2], 0);
    expect(s.canRedo, isTrue);
    s = reduce(s, const Redo());
    expect(s.values[2], 4);
    expect(s.canRedo, isFalse);
    expect(s.canUndo, isTrue);
    s = reduce(s, const Undo());
    s = reduce(s, const EnterDigit(1)); // a fresh change drops the redo trail
    expect(s.canRedo, isFalse);
    expect(identical(reduce(s, const Redo()), s), isTrue);
  });

  test('filling candidates twice adds only one undo entry', () {
    var s = reduce(fresh(), const FillCandidates());
    expect(s.undoStack.length, 1);
    final again = reduce(s, const FillCandidates());
    expect(identical(again, s), isTrue);
    expect(again.undoStack.length, 1);
  });

  test('candidate-count filters toggle independently, outside undo', () {
    var s = reduce(fresh(), const ToggleNoteCountFilter(2));
    expect(s.highlightsNoteCount(2), isTrue);
    expect(s.highlightsNoteCount(3), isFalse);
    s = reduce(s, const ToggleNoteCountFilter(3));
    expect(s.highlightsNoteCount(2), isTrue);
    expect(s.highlightsNoteCount(3), isTrue);
    s = reduce(s, const FillCandidates());
    expect(s.highlightsNoteCount(2), isTrue, reason: 'edits keep the filter');
    s = reduce(s, const ToggleNoteCountFilter(2));
    expect(s.highlightsNoteCount(2), isFalse);
    expect(s.highlightsNoteCount(3), isTrue);
    expect(s.undoStack.length, 1, reason: 'view toggles are not undoable');
    expect(identical(reduce(s, const ToggleNoteCountFilter(0)), s), isTrue);
  });

  group('paint', () {
    test('a cell toggles with the same color, repaints, erases, undoes', () {
      var s = reduce(fresh(), const PickPaint(2));
      s = reduce(s, const PaintCell(10));
      expect(s.cellColors[10], 2);
      expect(s.undoStack.length, 1);
      s = reduce(s, const PickPaint(5));
      s = reduce(s, const PaintCell(10));
      expect(s.cellColors[10], 5, reason: 'another color repaints');
      s = reduce(s, const PaintCell(10));
      expect(s.cellColors[10], 0, reason: 'the same color clears');
      s = reduce(s, const Undo());
      expect(s.cellColors[10], 5);
      s = reduce(s, const PickPaint(0)); // eraser
      s = reduce(s, const PaintCell(10));
      expect(s.cellColors[10], 0);
      expect(identical(reduce(s, const PaintCell(10)), s), isTrue);
    });

    test('only an existing mark takes paint; a placed digit prunes it', () {
      var s = reduce(fresh(), const FillCandidates());
      s = reduce(s, const PickPaint(3));
      expect(identical(reduce(s, const PaintNote(0, 1)), s), isTrue);
      // r1c3 (2) and r2c3 (11) share column and box; both hold mark 4.
      expect(s.notes[2] & (1 << 3), isNot(0));
      expect(s.notes[11] & (1 << 3), isNot(0));
      s = reduce(s, const PaintNote(2, 4));
      s = reduce(s, const PaintNote(11, 4));
      s = reduce(s, const PaintNote(11, 7));
      expect(s.noteColors[2 * 9 + 3], 3);
      expect(s.noteColors[11 * 9 + 3], 3);
      expect(s.noteColors[11 * 9 + 6], 3);
      s = reduce(s, const SelectCell(2));
      s = reduce(s, const EnterDigit(4));
      expect(s.noteColors[2 * 9 + 3], 0, reason: 'its own marks are gone');
      expect(s.noteColors[11 * 9 + 3], 0, reason: 'the peer lost mark 4');
      expect(s.noteColors[11 * 9 + 6], 3, reason: 'other marks keep paint');
      s = reduce(s, const Undo());
      expect(s.noteColors[2 * 9 + 3], 3, reason: 'undo restores paint');
    });

    test('clear paint wipes everything in one undo step', () {
      var s = reduce(fresh(), const FillCandidates());
      s = reduce(s, const PaintCell(0));
      s = reduce(s, const PaintNote(2, 4));
      expect(s.hasPaint, isTrue);
      final before = s.undoStack.length;
      s = reduce(s, const ClearPaint());
      expect(s.hasPaint, isFalse);
      expect(s.undoStack.length, before + 1);
      expect(identical(reduce(s, const ClearPaint()), s), isTrue);
      s = reduce(s, const Undo());
      expect(s.cellColors[0], 1);
      expect(s.noteColors[2 * 9 + 3], 1);
    });

    test('a color arms, the same one disarms, a digit key disarms', () {
      var s = reduce(fresh(), const PickPaint(4));
      expect(s.paintArmed, isTrue);
      expect(s.paintColor, 4);
      s = reduce(s, const PickPaint(4));
      expect(s.paintArmed, isFalse, reason: 'same swatch again disarms');
      expect(s.paintColor, 4, reason: 'the color is remembered');
      s = reduce(s, const PickPaint(0));
      expect(s.paintArmed, isTrue);
      expect(s.paintColor, 0, reason: 'eraser');
      s = reduce(s, const EnterDigit(7));
      expect(s.paintArmed, isFalse, reason: 'a digit key takes over');
      s = reduce(s, const SetPaintTarget(PaintTarget.note));
      expect(s.paintTarget, PaintTarget.note);
      expect(s.undoStack, isEmpty, reason: 'tool changes are not undoable');
    });
  });

  test('placing the last digit completes the game and locks the board', () {
    // Start from the solution with one cell blanked.
    final cells = GridCodec.parse(_solution);
    cells[2] = 0; // r1c3 is not a given
    var s = PlayState(
      givens: GridCodec.parse(_puzzle),
      solution: GridCodec.parse(_solution),
      values: cells,
      notes: Uint16List(81),
      seed: 1,
    );
    s = reduce(s, const SelectCell(2));
    s = reduce(s, const EnterDigit(4));
    expect(s.completed, isTrue);
    expect(isSolved(s.values), isTrue);
    // Edits are ignored afterwards; selection still works.
    final locked = reduce(s, const Erase());
    expect(identical(locked, s), isTrue);
    expect(identical(reduce(s, const Undo()), s), isTrue);
    expect(reduce(s, const SelectCell(0)).selected, 0);
  });

  test('solved detection', () {
    final done = GridCodec.parse(_solution);
    expect(isSolved(done), isTrue);
  });
}
