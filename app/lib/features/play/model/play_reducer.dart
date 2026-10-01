import 'dart:typed_data';

import 'package:sudoku_engine/sudoku_engine.dart';

import '../../settings/app_settings.dart';
import 'board_analysis.dart';
import 'play_intent.dart';
import 'play_state.dart';

/// Pure state transition. Returns the same instance when nothing changes,
/// so listeners can rely on identity.
///
/// [inputMode] decides what a board tap and a digit key mean:
/// cell-first taps select and keys write; digit-first keys pick a sticky
/// digit and taps write it.
PlayState reduce(
  PlayState state,
  PlayIntent intent, {
  InputMode inputMode = InputMode.cellFirst,
}) {
  // A finished board only accepts selection and highlighting.
  if (state.completed &&
      intent is! SelectCell &&
      intent is! ClearSelection &&
      intent is! ToggleNoteMode &&
      intent is! ToggleNoteCountFilter &&
      intent is! ToggleHighlight &&
      intent is! HoldDigit) {
    return state;
  }
  switch (intent) {
    case SelectCell(:final index):
      if (index < 0 || index > 80) return state;
      final digit = state.values[index];
      if (inputMode == InputMode.digitFirst &&
          !state.completed &&
          state.activeDigit != 0 &&
          !state.isGiven(index)) {
        final next = state.noteMode
            ? _toggleNote(state, index, state.activeDigit)
            : _write(state, index, state.activeDigit);
        return next.copyWith(selected: index);
      }
      if (state.selected == index && state.activeDigit == digit) return state;
      return state.copyWith(
        selected: index,
        activeDigit: digit,
        highlightSlots: _follow(state, digit),
      );

    case EnterDigit(:final digit):
      if (digit < 1 || digit > 9) return state;
      if (inputMode == InputMode.digitFirst) {
        // The key only arms (or disarms) the sticky digit; taps place it.
        final armed = state.activeDigit == digit ? 0 : digit;
        return state.copyWith(
          activeDigit: armed,
          highlightSlots: _follow(state, armed),
          paintArmed: false,
        );
      }
      final selected = state.selected;
      if (selected == null || state.isGiven(selected)) {
        // Nothing to write: the key only picks the highlighted digit, and
        // a tap always means one digit.
        return _pick(state, digit);
      }
      return _write(state, selected, digit).copyWith(
        activeDigit: digit,
        highlightSlots: _follow(state, digit),
        paintArmed: false,
      );

    case EnterNote(:final digit):
      if (digit < 1 || digit > 9) return state;
      final selected = state.selected;
      if (selected == null || state.values[selected] != 0) {
        return _pick(state, digit);
      }
      return _toggleNote(state, selected, digit).copyWith(
        activeDigit: digit,
        highlightSlots: _follow(state, digit),
        paintArmed: false,
      );

    case ToggleNoteMode():
      return state.copyWith(noteMode: !state.noteMode);

    case ToggleNoteCountFilter(:final count):
      if (count < 1 || count > 9) return state;
      return state.copyWith(
        noteCountFilter: state.noteCountFilter ^ (1 << count),
      );

    case ToggleHighlight(:final digit):
      if (digit < 1 || digit > 9) return state;
      final slots = List<int>.of(state.highlightSlots);
      final at = slots.indexOf(digit);
      if (at >= 0) {
        slots[at] = 0;
      } else {
        final free = slots.indexOf(0);
        if (free < 0) return state;
        slots[free] = digit;
      }
      final lit = [
        for (final d in slots)
          if (d != 0) d,
      ];
      // Digit-first: the active digit is the armed one, and a highlight
      // must never arm anything, or the next cell tap would write it.
      final armed = inputMode == InputMode.digitFirst;
      if (lit.length <= 1) {
        // Down to one digit (or none): it takes the standard blue again,
        // and stays pinned while anything is lit.
        final only = lit.isEmpty ? 0 : lit.first;
        return state.copyWith(
          activeDigit: armed ? state.activeDigit : only,
          highlightSlots: _single(only),
          highlightPinned: only != 0,
        );
      }
      // Cell-first: the digit touched last is the active one (a board
      // long press writes it). Removing it hands over to the newest.
      final int active;
      if (armed) {
        active = state.activeDigit;
      } else if (at < 0) {
        active = digit;
      } else if (state.activeDigit == digit) {
        active = lit.last;
      } else {
        active = state.activeDigit;
      }
      return state.copyWith(
        activeDigit: active,
        highlightSlots: List.unmodifiable(slots),
        highlightPinned: true,
      );

    case HoldDigit(:final digit):
      if (digit < 1 || digit > 9) return state;
      final selected = state.selected;
      if (inputMode == InputMode.cellFirst &&
          !state.completed &&
          selected != null &&
          !state.isGiven(selected)) {
        // The escape hatch from note mode: a held key always writes a value.
        return _write(
          state,
          selected,
          digit,
        ).copyWith(activeDigit: digit, highlightSlots: _follow(state, digit));
      }
      return reduce(state, ToggleHighlight(digit), inputMode: inputMode);

    case PlaceAt(:final index):
      if (index < 0 || index > 80) return state;
      if (state.activeDigit == 0 || state.isGiven(index)) {
        return state.selected == index
            ? state
            : state.copyWith(selected: index);
      }
      return _write(state, index, state.activeDigit).copyWith(selected: index);

    case Erase():
      final selected = state.selected;
      if (selected == null || state.isGiven(selected)) return state;
      if (state.values[selected] != 0) {
        final values = Uint8List.fromList(state.values);
        values[selected] = 0;
        return state.remember().copyWith(values: values);
      }
      if (state.notes[selected] == 0) return state;
      final notes = Uint16List.fromList(state.notes);
      notes[selected] = 0;
      return state.remember().copyWith(
        notes: notes,
        noteColors: _prunedNoteColors(notes, state.noteColors),
      );

    case SetPaintTarget(:final target):
      if (state.paintTarget == target) return state;
      return state.copyWith(paintTarget: target);

    case PickPaint(:final color):
      if (color < 0 || color > kPaintColors) return state;
      if (state.paintArmed && color == state.paintColor) {
        return state.copyWith(paintArmed: false);
      }
      return state.copyWith(paintColor: color, paintArmed: true);

    case PaintCell(:final index):
      if (index < 0 || index > 80) return state;
      final next = _toggledPaint(state.cellColors[index], state.paintColor);
      if (next == state.cellColors[index]) return state;
      final colors = Uint8List.fromList(state.cellColors);
      colors[index] = next;
      return state.remember().copyWith(cellColors: colors);

    case PaintNote(:final index, :final digit):
      if (index < 0 || index > 80 || digit < 1 || digit > 9) return state;
      if (state.values[index] != 0 ||
          state.notes[index] & (1 << (digit - 1)) == 0) {
        return state; // only an existing mark can be painted
      }
      final at = index * 9 + digit - 1;
      final next = _toggledPaint(state.noteColors[at], state.paintColor);
      if (next == state.noteColors[at]) return state;
      final colors = Uint8List.fromList(state.noteColors);
      colors[at] = next;
      return state.remember().copyWith(noteColors: colors);

    case ClearPaint():
      if (!state.hasPaint) return state;
      return state.remember().copyWith(
        cellColors: kNoCellColors,
        noteColors: kNoNoteColors,
      );

    case Undo():
      if (!state.canUndo) return state;
      final last = state.undoStack.last;
      return state.copyWith(
        values: last.values,
        notes: last.notes,
        cellColors: last.cellColors,
        noteColors: last.noteColors,
        undoStack: List.unmodifiable(
          state.undoStack.sublist(0, state.undoStack.length - 1),
        ),
        redoStack: List.unmodifiable([...state.redoStack, state.snapshot()]),
      );

    case Redo():
      if (!state.canRedo) return state;
      final next = state.redoStack.last;
      return state.copyWith(
        values: next.values,
        notes: next.notes,
        cellColors: next.cellColors,
        noteColors: next.noteColors,
        completed: isSolved(next.values),
        undoStack: List.unmodifiable([...state.undoStack, state.snapshot()]),
        redoStack: List.unmodifiable(
          state.redoStack.sublist(0, state.redoStack.length - 1),
        ),
      );

    case ClearSelection():
      if (state.selected == null &&
          state.activeDigit == 0 &&
          state.highlightOrder.isEmpty) {
        return state;
      }
      return state.copyWith(
        clearSelection: true,
        activeDigit: 0,
        highlightSlots: kNoHighlights,
        highlightPinned: false,
      );

    case FillCandidates():
      final values = state.values;
      final notes = Uint16List(81);
      final peers = Tables.instance.peers;
      for (var i = 0; i < 81; i++) {
        if (values[i] != 0) continue;
        var mask = Tables.kAll;
        for (var k = 0; k < 20; k++) {
          final v = values[peers[i * 20 + k]];
          if (v != 0) mask &= ~(1 << (v - 1));
        }
        notes[i] = mask;
      }
      var same = true;
      for (var i = 0; i < 81 && same; i++) {
        same = notes[i] == state.notes[i];
      }
      if (same) return state; // nothing changed: no undo entry
      return state.remember().copyWith(
        notes: notes,
        noteColors: _prunedNoteColors(notes, state.noteColors),
      );
  }
}

/// Paint value after tapping a target that holds [current] with [picked]:
/// the eraser or the same color clears, anything else recolors.
int _toggledPaint(int current, int picked) =>
    picked == 0 || picked == current ? 0 : picked;

/// Mark colors with every entry whose mark no longer exists cleared. Returns
/// [colors] itself when nothing has to go.
Uint8List _prunedNoteColors(Uint16List notes, Uint8List colors) {
  Uint8List? pruned;
  for (var i = 0; i < 81; i++) {
    for (var d = 0; d < 9; d++) {
      final at = i * 9 + d;
      if (colors[at] != 0 && notes[i] & (1 << d) == 0) {
        pruned ??= Uint8List.fromList(colors);
        pruned[at] = 0;
      }
    }
  }
  return pruned ?? colors;
}

/// Highlight after a tap on key [digit] that has nothing to write: always
/// that one digit, unpinned, which also ends a long-press set.
PlayState _pick(PlayState state, int digit) {
  if (state.activeDigit == digit &&
      !state.highlightPinned &&
      !state.paintArmed) {
    return state;
  }
  return state.copyWith(
    activeDigit: digit,
    highlightSlots: _single(digit),
    highlightPinned: false,
    paintArmed: false,
  );
}

/// Highlight after the player touches [digit] (0 for an empty cell): a
/// pinned (long-press) set stays, otherwise the highlight follows.
List<int> _follow(PlayState state, int digit) =>
    state.highlightPinned ? state.highlightSlots : _single(digit);

/// Only [digit] lit, in the first (blue) slot.
List<int> _single(int digit) {
  if (digit == 0) return kNoHighlights;
  final slots = List<int>.of(kNoHighlights);
  slots[0] = digit;
  return List.unmodifiable(slots);
}

/// Writes [digit] into [index], or clears the cell when it already holds
/// that digit. A placed digit clears the cell's own marks and that digit
/// from its 20 peers' marks.
PlayState _write(PlayState state, int index, int digit) {
  state = state.remember();
  final values = Uint8List.fromList(state.values);
  final cleared = values[index] == digit;
  values[index] = cleared ? 0 : digit;
  if (cleared) return state.copyWith(values: values);
  if (isSolved(values)) {
    return state.copyWith(values: values, completed: true);
  }
  final notes = Uint16List.fromList(state.notes);
  notes[index] = 0;
  final bit = 1 << (digit - 1);
  final peers = Tables.instance.peers;
  for (var k = 0; k < 20; k++) {
    notes[peers[index * 20 + k]] &= ~bit;
  }
  return state.copyWith(
    values: values,
    notes: notes,
    noteColors: _prunedNoteColors(notes, state.noteColors),
  );
}

/// Flips pencil mark [digit] in empty cell [index].
PlayState _toggleNote(PlayState state, int index, int digit) {
  if (state.values[index] != 0) return state;
  state = state.remember();
  final notes = Uint16List.fromList(state.notes);
  notes[index] ^= 1 << (digit - 1);
  return state.copyWith(
    notes: notes,
    noteColors: _prunedNoteColors(notes, state.noteColors),
  );
}
