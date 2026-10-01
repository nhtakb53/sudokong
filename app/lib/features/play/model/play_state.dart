import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:sudoku_engine/sudoku_engine.dart';

/// Board contents at one point in time, kept for undo: digits, pencil
/// marks, the player's paint and links.
@immutable
class BoardSnapshot {
  const BoardSnapshot(
    this.values,
    this.notes,
    this.cellColors,
    this.noteColors,
    this.links,
  );
  final Uint8List values;
  final Uint16List notes;
  final Uint8List cellColors;
  final Uint8List noteColors;
  final List<NoteLink> links;
}

/// A link the player drew between two pencil marks. A strong link joins
/// the two marks of a bivalue cell or a conjugate pair (the only two cells
/// of a unit holding that digit); a weak link joins marks that merely see
/// each other.
@immutable
class NoteLink {
  const NoteLink({
    required this.cellA,
    required this.digitA,
    required this.cellB,
    required this.digitB,
    required this.strong,
    this.manual = false,
  });

  final int cellA;
  final int digitA;
  final int cellB;
  final int digitB;
  final bool strong;

  /// True once the player set the type by hand; recomputation leaves it.
  final bool manual;

  bool touches(int cell, int digit) =>
      (cellA == cell && digitA == digit) || (cellB == cell && digitB == digit);

  bool joins(int ca, int da, int cb, int db) =>
      (cellA == ca && digitA == da && cellB == cb && digitB == db) ||
      (cellA == cb && digitA == db && cellB == ca && digitB == da);

  NoteLink copyWith({bool? strong, bool? manual}) => NoteLink(
    cellA: cellA,
    digitA: digitA,
    cellB: cellB,
    digitB: digitB,
    strong: strong ?? this.strong,
    manual: manual ?? this.manual,
  );
}

/// One end of a link being drawn.
typedef LinkEnd = ({int cell, int digit});

/// What a tap paints while paint mode is on.
enum PaintTarget { cell, note }

/// Paint palette size; a paint value is 1-based into [BoardColors.digitSlots],
/// 0 meaning unpainted (or, as the picked color, the eraser).
const int kPaintColors = 9;

/// Most snapshots kept for undo.
const int kUndoLimit = 100;

/// No digit highlighted: nine free color slots, one per digit.
const List<int> kNoHighlights = [0, 0, 0, 0, 0, 0, 0, 0, 0];

/// Unpainted boards share these; the reducer copies before writing.
final Uint8List kNoCellColors = Uint8List(81);
final Uint8List kNoNoteColors = Uint8List(81 * 9);

/// Immutable state of one game in progress.
///
/// The typed lists are never mutated after construction; the reducer
/// allocates new ones when something changes.
@immutable
class PlayState {
  PlayState({
    required this.givens,
    required this.solution,
    required this.values,
    required this.notes,
    required this.seed,
    this.selected,
    this.activeDigit = 0,
    this.noteMode = false,
    this.undoStack = const [],
    this.redoStack = const [],
    this.completed = false,
    this.noteCountFilter = 0,
    this.highlightSlots = kNoHighlights,
    this.highlightPinned = false,
    Uint8List? cellColors,
    Uint8List? noteColors,
    this.paintArmed = false,
    this.paintTarget = PaintTarget.cell,
    this.paintColor = 1,
    this.links = const [],
    this.linkStart,
    this.linkArmed = false,
  }) : cellColors = cellColors ?? kNoCellColors,
       noteColors = noteColors ?? kNoNoteColors;

  factory PlayState.fromPuzzle(GeneratedPuzzle puzzle) {
    final givens = GridCodec.parse(puzzle.puzzle);
    return PlayState(
      givens: givens,
      solution: GridCodec.parse(puzzle.solution),
      values: Uint8List.fromList(givens),
      notes: Uint16List(81),
      seed: puzzle.seed,
    );
  }

  /// Player's paint per cell: 0 = none, else a 1-based palette index.
  final Uint8List cellColors;

  /// Player's paint per pencil mark, indexed `cell * 9 + digit - 1`.
  final Uint8List noteColors;

  /// True while a palette color (or the eraser) is the armed tool, so board
  /// taps paint instead of selecting. Any digit key disarms it.
  final bool paintArmed;

  /// Whether a paint tap colors the cell or the nearest pencil mark.
  final PaintTarget paintTarget;

  /// The palette color last picked (1-based), or 0 for the eraser.
  final int paintColor;

  bool get hasPaint =>
      cellColors.any((c) => c != 0) || noteColors.any((c) => c != 0);

  /// True while there is something to come back to: an unfinished board
  /// that differs from the puzzle as given, or carries marks, paint or
  /// links.
  bool get hasProgress {
    if (completed) return false;
    for (var i = 0; i < 81; i++) {
      if (values[i] != givens[i] || notes[i] != 0) return true;
    }
    return hasPaint || links.isNotEmpty;
  }

  /// Links drawn between pencil marks, in drawing order.
  final List<NoteLink> links;

  /// The mark the next link starts from while the link tool is armed.
  final LinkEnd? linkStart;

  /// True while the link tool is the armed tool, so mark taps draw links.
  final bool linkArmed;

  /// Given digits, 0 where the cell was empty at the start.
  final Uint8List givens;

  /// The unique solution, kept for completion checks.
  final Uint8List solution;

  /// Current board including givens, 0 = empty.
  final Uint8List values;

  /// Pencil marks per cell as 9-bit masks.
  final Uint16List notes;

  /// Generator seed of this puzzle.
  final int seed;

  /// Selected cell index, or `null`.
  final int? selected;

  /// Digit highlighted across the board (1-9), or 0. Set by the last digit
  /// key pressed or the last cell selected.
  final int activeDigit;

  /// When true, digit keys write pencil marks instead of values.
  final bool noteMode;

  /// Previous boards, oldest first. Empty when there is nothing to undo.
  final List<BoardSnapshot> undoStack;

  /// Boards undone since the last change, most recently undone last.
  final List<BoardSnapshot> redoStack;

  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  /// True once every cell is filled without a rule conflict. Board edits
  /// are ignored from then on.
  final bool completed;

  /// Which pencil-mark counts to spotlight, as a bitmask: bit `n` set means
  /// every empty cell holding exactly `n` marks is tinted. A view toggle,
  /// not a board change, so undo never touches it.
  final int noteCountFilter;

  bool highlightsNoteCount(int count) => noteCountFilter & (1 << count) != 0;

  /// Highlighted digit per color slot, 0 where the slot is free. A digit
  /// keeps its slot (and color) while others come and go. One lit digit
  /// follows whatever was touched last (a tapped cell or key); two or more
  /// are a set built with long presses, which stays put until a key tap or
  /// a tap on empty space replaces it.
  final List<int> highlightSlots;

  /// Highlighted digits in slot order.
  List<int> get highlightOrder => [
    for (final d in highlightSlots)
      if (d != 0) d,
  ];

  bool highlights(int digit) => digit != 0 && highlightSlots.contains(digit);

  /// Color slot of a highlighted digit, or -1.
  int slotOf(int digit) => digit == 0 ? -1 : highlightSlots.indexOf(digit);

  /// True while the highlight was set by long presses. A pinned highlight
  /// stays put through cell taps and writes until a key tap or a tap on
  /// empty space replaces it; an unpinned one follows whatever is touched.
  final bool highlightPinned;

  bool isGiven(int index) => givens[index] != 0;

  PlayState copyWith({
    Uint8List? values,
    Uint16List? notes,
    int? selected,
    bool clearSelection = false,
    int? activeDigit,
    bool? noteMode,
    List<BoardSnapshot>? undoStack,
    List<BoardSnapshot>? redoStack,
    bool? completed,
    int? noteCountFilter,
    List<int>? highlightSlots,
    bool? highlightPinned,
    Uint8List? cellColors,
    Uint8List? noteColors,
    bool? paintArmed,
    PaintTarget? paintTarget,
    int? paintColor,
    List<NoteLink>? links,
    LinkEnd? linkStart,
    bool clearLinkStart = false,
    bool? linkArmed,
  }) {
    return PlayState(
      givens: givens,
      solution: solution,
      values: values ?? this.values,
      notes: notes ?? this.notes,
      seed: seed,
      selected: clearSelection ? null : (selected ?? this.selected),
      activeDigit: activeDigit ?? this.activeDigit,
      noteMode: noteMode ?? this.noteMode,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
      completed: completed ?? this.completed,
      noteCountFilter: noteCountFilter ?? this.noteCountFilter,
      highlightSlots: highlightSlots ?? this.highlightSlots,
      highlightPinned: highlightPinned ?? this.highlightPinned,
      cellColors: cellColors ?? this.cellColors,
      noteColors: noteColors ?? this.noteColors,
      paintArmed: paintArmed ?? this.paintArmed,
      paintTarget: paintTarget ?? this.paintTarget,
      paintColor: paintColor ?? this.paintColor,
      links: links ?? this.links,
      linkStart: clearLinkStart ? null : (linkStart ?? this.linkStart),
      linkArmed: linkArmed ?? this.linkArmed,
    );
  }

  /// The board as it is now, for undo.
  BoardSnapshot snapshot() =>
      BoardSnapshot(values, notes, cellColors, noteColors, links);

  /// Copy with the current board pushed onto the undo stack. A new change
  /// invalidates whatever was undone before it.
  PlayState remember() {
    final stack = [...undoStack, snapshot()];
    if (stack.length > kUndoLimit) stack.removeAt(0);
    return copyWith(undoStack: List.unmodifiable(stack), redoStack: const []);
  }
}
