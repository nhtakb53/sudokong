import 'play_state.dart' show PaintTarget;

/// Everything the player can do to the board.
sealed class PlayIntent {
  const PlayIntent();
}

/// Select the cell at [index] (0..80).
final class SelectCell extends PlayIntent {
  const SelectCell(this.index);
  final int index;
}

/// Enter [digit] (1..9) into the selected cell. Entering the digit that is
/// already there clears the cell.
final class EnterDigit extends PlayIntent {
  const EnterDigit(this.digit);
  final int digit;
}

/// Fill every empty cell's pencil marks with the digits its row, column and
/// box still allow. Existing marks are replaced.
final class FillCandidates extends PlayIntent {
  const FillCandidates();
}

/// Drop the selected cell and the highlighted digit.
final class ClearSelection extends PlayIntent {
  const ClearSelection();
}

/// Toggle pencil mark [digit] in the selected cell (cell-first input).
final class EnterNote extends PlayIntent {
  const EnterNote(this.digit);
  final int digit;
}

/// Flip note mode on or off.
final class ToggleNoteMode extends PlayIntent {
  const ToggleNoteMode();
}

/// Toggle the tint on every empty cell holding exactly [count] pencil marks.
final class ToggleNoteCountFilter extends PlayIntent {
  const ToggleNoteCountFilter(this.count);
  final int count;
}

/// Add [digit] to the highlighted set, or remove it when it is already
/// there. Each digit in the set gets its own color.
final class ToggleHighlight extends PlayIntent {
  const ToggleHighlight(this.digit);
  final int digit;
}

/// A long press on a digit key. With a writable cell selected (cell-first)
/// it writes the value whatever the note mode; otherwise it is
/// [ToggleHighlight].
final class HoldDigit extends PlayIntent {
  const HoldDigit(this.digit);
  final int digit;
}

/// Digit-first only: write the armed digit as a value into [index], ignoring
/// note mode (the long-press escape hatch on the board).
final class PlaceAt extends PlayIntent {
  const PlaceAt(this.index);
  final int index;
}

/// Clear the selected cell: its value if it has one, otherwise its marks.
final class Erase extends PlayIntent {
  const Erase();
}

/// Choose whether paint taps color cells or pencil marks.
final class SetPaintTarget extends PlayIntent {
  const SetPaintTarget(this.target);
  final PaintTarget target;
}

/// Arm palette color [color] (1-based), or 0 for the eraser. Picking the
/// armed one again disarms, and so does any digit key.
final class PickPaint extends PlayIntent {
  const PickPaint(this.color);
  final int color;
}

/// Paint cell [index] with the picked color; the same color again, or the
/// eraser, clears it.
final class PaintCell extends PlayIntent {
  const PaintCell(this.index);
  final int index;
}

/// Paint pencil mark [digit] in cell [index] the same way.
final class PaintNote extends PlayIntent {
  const PaintNote(this.index, this.digit);
  final int index;
  final int digit;
}

/// Remove every cell and pencil-mark color.
final class ClearPaint extends PlayIntent {
  const ClearPaint();
}

/// Restore the board as it was before the last change.
final class Undo extends PlayIntent {
  const Undo();
}

/// Re-apply the change most recently undone.
final class Redo extends PlayIntent {
  const Redo();
}
