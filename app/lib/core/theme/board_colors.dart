import 'package:flutter/material.dart';

/// One color set for a highlighted digit: the fill behind a placed digit
/// and the chip (with its text color) behind a matching pencil mark.
@immutable
class HighlightSlot {
  const HighlightSlot({
    required this.fill,
    required this.chip,
    required this.chipText,
  });

  final Color fill;
  final Color chip;
  final Color chipText;

  HighlightSlot lerp(HighlightSlot other, double t) => HighlightSlot(
    fill: Color.lerp(fill, other.fill, t)!,
    chip: Color.lerp(chip, other.chip, t)!,
    chipText: Color.lerp(chipText, other.chipText, t)!,
  );

  @override
  bool operator ==(Object other) =>
      other is HighlightSlot &&
      other.fill == fill &&
      other.chip == chip &&
      other.chipText == chipText;

  @override
  int get hashCode => Object.hash(fill, chip, chipText);
}

/// Board palette. The values follow the convention shared by the most
/// widely used sudoku apps: neutral givens, blue entries, pale blue
/// highlights in three tiers (peers < same digit < selected).
@immutable
class BoardColors extends ThemeExtension<BoardColors> {
  const BoardColors({
    required this.cell,
    required this.peer,
    required this.sameDigit,
    required this.selected,
    required this.conflictCell,
    required this.given,
    required this.entry,
    required this.note,
    required this.noteOnPeer,
    required this.conflictText,
    required this.lineThin,
    required this.lineThick,
    required this.noteHighlightFill,
    required this.noteHighlightText,
    required this.twoNotesTile,
    required this.threeNotesTile,
    required this.extraSlots,
    required this.linkStrong,
    required this.linkWeak,
    required this.linkStrongText,
    required this.linkWeakText,
  });

  final Color cell;
  final Color peer;
  final Color sameDigit;
  final Color selected;
  final Color conflictCell;
  final Color given;
  final Color entry;
  final Color note;

  /// Pencil marks inside the selected cell's row, column and box, where
  /// the peer tint would otherwise pull [note] down to the legal minimum.
  final Color noteOnPeer;

  final Color conflictText;
  final Color lineThin;
  final Color lineThick;

  /// Chip drawn behind a pencil mark that matches the highlighted digit.
  final Color noteHighlightFill;

  /// Pencil-mark digit drawn on top of [noteHighlightFill].
  final Color noteHighlightText;

  /// Fill for an empty cell with exactly two pencil marks, when that filter
  /// is on. Soft, and the marks on it use the given color.
  final Color twoNotesTile;

  /// Fill for an empty cell with exactly three pencil marks.
  final Color threeNotesTile;

  /// Strong link between pencil marks (drawn solid) and weak link (dashed).
  final Color linkStrong;
  final Color linkWeak;

  /// Digits on the chips at a link's ends (and on the start chip).
  final Color linkStrongText;
  final Color linkWeakText;

  /// Colors for the second to ninth digit highlighted at once: amber,
  /// peach, green, violet, pink, teal, lime, gray.
  /// The first highlighted digit keeps the standard blue ([sameDigit],
  /// [noteHighlightFill], [noteHighlightText]).
  final List<HighlightSlot> extraSlots;

  /// Color set per highlight position: the standard blue first, then
  /// [extraSlots].
  List<HighlightSlot> get digitSlots => [
    HighlightSlot(
      fill: sameDigit,
      chip: noteHighlightFill,
      chipText: noteHighlightText,
    ),
    ...extraSlots,
  ];

  // Off-white instead of pure white, so a bright screen does not glare.
  static const light = BoardColors(
    cell: Color(0xFFF8F9FB),
    peer: Color(0xFFDCE6F2),
    sameDigit: Color(0xFFBFD6EE),
    selected: Color(0xFFA9D2F9),
    conflictCell: Color(0xFFF7CFD6),
    // Three text roles that read apart at a glance: near-black ink for
    // givens, royal blue for entries, a muted steel blue for pencil marks.
    // Marks cannot get lighter (4.5:1 on the peer band), so hue does the
    // separating.
    given: Color(0xFF1C2736),
    entry: Color(0xFF325AAF),
    note: Color(0xFF46648A),
    noteOnPeer: Color(0xFF334964),
    conflictText: Color(0xFFE55C5C),
    // Translucent so the grid stays visible over highlight fills.
    lineThin: Color(0x2E344861),
    lineThick: Color(0xFF4A5B75),
    noteHighlightFill: Color(0xFF325AAF),
    noteHighlightText: Color(0xFFFFFFFF),
    twoNotesTile: Color(0xFFA8D8DC),
    threeNotesTile: Color(0xFFCFC5EF),
    linkStrong: Color(0xFFB8511A),
    linkWeak: Color(0xFF54728F),
    linkStrongText: Color(0xFFFFFFFF),
    linkWeakText: Color(0xFFFFFFFF),
    extraSlots: [
      // amber
      HighlightSlot(
        fill: Color(0xFFF6E0A0),
        chip: Color(0xFFE3B23C),
        chipText: Color(0xFF2B2000),
      ),
      // peach
      HighlightSlot(
        fill: Color(0xFFF9D9C2),
        chip: Color(0xFFB84E22),
        chipText: Color(0xFFFFFFFF),
      ),
      // green
      HighlightSlot(
        fill: Color(0xFFCBE6C9),
        chip: Color(0xFF2F7A42),
        chipText: Color(0xFFFFFFFF),
      ),
      // violet
      HighlightSlot(
        fill: Color(0xFFE3D6F5),
        chip: Color(0xFF7A52C9),
        chipText: Color(0xFFFFFFFF),
      ),
      // pink
      HighlightSlot(
        fill: Color(0xFFF6D3E8),
        chip: Color(0xFFB83A86),
        chipText: Color(0xFFFFFFFF),
      ),
      // teal
      HighlightSlot(
        fill: Color(0xFFBEE4E6),
        chip: Color(0xFF197A6B),
        chipText: Color(0xFFFFFFFF),
      ),
      // lime
      HighlightSlot(
        fill: Color(0xFFDEE8AE),
        chip: Color(0xFFAFC63A),
        chipText: Color(0xFF1F2600),
      ),
      // gray
      HighlightSlot(
        fill: Color(0xFFE2E0DC),
        chip: Color(0xFF6B7280),
        chipText: Color(0xFFFFFFFF),
      ),
    ],
  );

  // Near-neutral dark grays; the blue tiers keep a little hue so the
  // peer, same-digit and selected cells still read as tiers.
  static const dark = BoardColors(
    cell: Color(0xFF1E2024),
    peer: Color(0xFF2B3340),
    sameDigit: Color(0xFF374C66),
    selected: Color(0xFF3C5A82),
    conflictCell: Color(0xFF4B2A33),
    // White givens, sky-blue entries, neutral gray marks. The gray is as
    // dim as 4.5:1 on the peer band allows, so it sits well below the
    // white givens.
    given: Color(0xFFF0F4F8),
    entry: Color(0xFF7FB1F5),
    note: Color(0xFF969CA5),
    noteOnPeer: Color(0xFFBEC4CA),
    conflictText: Color(0xFFFF7B7B),
    // Translucent so the grid stays visible over highlight fills.
    lineThin: Color(0x1FFFFFFF),
    lineThick: Color(0xFF656B75),
    noteHighlightFill: Color(0xFF7FB1F5),
    noteHighlightText: Color(0xFF0E1B33),
    twoNotesTile: Color(0xFF1D565D),
    threeNotesTile: Color(0xFF4A4188),
    linkStrong: Color(0xFFF0A05A),
    linkWeak: Color(0xFF8FA8C8),
    linkStrongText: Color(0xFF2A1508),
    linkWeakText: Color(0xFF0E1B33),
    extraSlots: [
      // amber
      HighlightSlot(
        fill: Color(0xFF5E4612),
        chip: Color(0xFFE3B23C),
        chipText: Color(0xFF2B2000),
      ),
      // peach
      HighlightSlot(
        fill: Color(0xFF5E3220),
        chip: Color(0xFFE8865A),
        chipText: Color(0xFF2A1208),
      ),
      // green
      HighlightSlot(
        fill: Color(0xFF27492B),
        chip: Color(0xFF5BBF72),
        chipText: Color(0xFF0B2512),
      ),
      // violet
      HighlightSlot(
        fill: Color(0xFF4A3A78),
        chip: Color(0xFFB493F0),
        chipText: Color(0xFF1E1140),
      ),
      // pink
      HighlightSlot(
        fill: Color(0xFF5C2A4E),
        chip: Color(0xFFE87DC0),
        chipText: Color(0xFF2E0B22),
      ),
      // teal
      HighlightSlot(
        fill: Color(0xFF154A52),
        chip: Color(0xFF5CC7B2),
        chipText: Color(0xFF072A24),
      ),
      // lime
      HighlightSlot(
        fill: Color(0xFF425416),
        chip: Color(0xFFC5DA55),
        chipText: Color(0xFF1F2600),
      ),
      // gray
      HighlightSlot(
        fill: Color(0xFF4C4944),
        chip: Color(0xFFB0B7C3),
        chipText: Color(0xFF1B1F26),
      ),
    ],
  );

  @override
  BoardColors copyWith({
    Color? cell,
    Color? peer,
    Color? sameDigit,
    Color? selected,
    Color? conflictCell,
    Color? given,
    Color? entry,
    Color? note,
    Color? noteOnPeer,
    Color? conflictText,
    Color? lineThin,
    Color? lineThick,
    Color? noteHighlightFill,
    Color? noteHighlightText,
    Color? twoNotesTile,
    Color? threeNotesTile,
    List<HighlightSlot>? extraSlots,
    Color? linkStrong,
    Color? linkWeak,
    Color? linkStrongText,
    Color? linkWeakText,
  }) {
    return BoardColors(
      cell: cell ?? this.cell,
      peer: peer ?? this.peer,
      sameDigit: sameDigit ?? this.sameDigit,
      selected: selected ?? this.selected,
      conflictCell: conflictCell ?? this.conflictCell,
      given: given ?? this.given,
      entry: entry ?? this.entry,
      note: note ?? this.note,
      noteOnPeer: noteOnPeer ?? this.noteOnPeer,
      conflictText: conflictText ?? this.conflictText,
      lineThin: lineThin ?? this.lineThin,
      lineThick: lineThick ?? this.lineThick,
      noteHighlightFill: noteHighlightFill ?? this.noteHighlightFill,
      noteHighlightText: noteHighlightText ?? this.noteHighlightText,
      twoNotesTile: twoNotesTile ?? this.twoNotesTile,
      threeNotesTile: threeNotesTile ?? this.threeNotesTile,
      extraSlots: extraSlots ?? this.extraSlots,
      linkStrong: linkStrong ?? this.linkStrong,
      linkWeak: linkWeak ?? this.linkWeak,
      linkStrongText: linkStrongText ?? this.linkStrongText,
      linkWeakText: linkWeakText ?? this.linkWeakText,
    );
  }

  @override
  BoardColors lerp(ThemeExtension<BoardColors>? other, double t) {
    if (other is! BoardColors) return this;
    return BoardColors(
      cell: Color.lerp(cell, other.cell, t)!,
      peer: Color.lerp(peer, other.peer, t)!,
      sameDigit: Color.lerp(sameDigit, other.sameDigit, t)!,
      selected: Color.lerp(selected, other.selected, t)!,
      conflictCell: Color.lerp(conflictCell, other.conflictCell, t)!,
      given: Color.lerp(given, other.given, t)!,
      entry: Color.lerp(entry, other.entry, t)!,
      note: Color.lerp(note, other.note, t)!,
      noteOnPeer: Color.lerp(noteOnPeer, other.noteOnPeer, t)!,
      conflictText: Color.lerp(conflictText, other.conflictText, t)!,
      lineThin: Color.lerp(lineThin, other.lineThin, t)!,
      lineThick: Color.lerp(lineThick, other.lineThick, t)!,
      noteHighlightFill: Color.lerp(
        noteHighlightFill,
        other.noteHighlightFill,
        t,
      )!,
      noteHighlightText: Color.lerp(
        noteHighlightText,
        other.noteHighlightText,
        t,
      )!,
      twoNotesTile: Color.lerp(twoNotesTile, other.twoNotesTile, t)!,
      threeNotesTile: Color.lerp(threeNotesTile, other.threeNotesTile, t)!,
      extraSlots: [
        for (var i = 0; i < extraSlots.length; i++)
          i < other.extraSlots.length
              ? extraSlots[i].lerp(other.extraSlots[i], t)
              : extraSlots[i],
      ],
      linkStrong: Color.lerp(linkStrong, other.linkStrong, t)!,
      linkWeak: Color.lerp(linkWeak, other.linkWeak, t)!,
      linkStrongText: Color.lerp(linkStrongText, other.linkStrongText, t)!,
      linkWeakText: Color.lerp(linkWeakText, other.linkWeakText, t)!,
    );
  }
}
