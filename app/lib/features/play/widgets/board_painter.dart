import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:sudoku_engine/sudoku_engine.dart';

import '../../../core/theme/board_colors.dart';
import '../../settings/app_settings.dart';
import '../model/board_analysis.dart';
import '../model/play_state.dart';
import 'board_text_cache.dart';
import 'link_geometry.dart';

/// Width divided by height of the whole board. Slightly below 1 makes each
/// cell a little taller than wide, which gives digits and notes more room
/// without the board looking stretched.
const double kBoardAspectRatio = 1 / 1.08;

/// Digit size relative to the cell width.
const double kDigitScale = 0.76;

/// Pencil-mark size relative to the cell width.
const double kNoteScale = 0.39;

/// Inset of the 3×3 pencil-mark grid from the cell edges, as a fraction of
/// the cell size, so corner marks never touch the grid lines.
const double kNoteInset = 0.02;

/// Corner radius of the board's outer border, in logical pixels.
const double kBoardCornerRadius = 6;

/// Corner radius of the selected cell's highlight.
const double kSelectionRadius = 5;

/// How far the selection tile grows past the cell on each side, so it
/// covers the grid lines around the cell.
const double kSelectionOverflow = 0.5;

/// Corner radius of a note chip. Lit chips fill their note cells edge to
/// edge; where two lit chips touch, the shared corners are square so the
/// group reads as one shape.
const double kNoteChipRadius = 3;

/// Links between pencil marks: stroke, dash pattern for weak links, the
/// strong/weak handle, and the chips on the two ends.
const double kLinkWidth = 2.2;
const double kLinkDashOn = 6;
const double kLinkDashOff = 4;
const double kLinkHandleRadius = 2.6;

/// Halo around the mark the next link starts from, past its chip.
const double kLinkStartHalo = 3.5;
const double kLinkChipRadius = 4;

/// How much of a link is left off at each end, so the line starts at the
/// end ring instead of crossing the mark's glyph.
const double kLinkEndTrim = 7.5;

/// Stroke widths in logical pixels.
const double kThinLineWidth = 1;
const double kThickLineWidth = 2;
const double kOuterLineWidth = 1.2;

/// Cap height of the digit font as a fraction of the font size. Digits are
/// centered on this box, not on the line box, so they sit visually centered.
const double kDigitCapHeight = 0.72;

class BoardPainter extends CustomPainter {
  BoardPainter({
    required this.state,
    required this.colors,
    required this.cache,
    required this.fontFamily,
    this.noteHighlightShape = NoteHighlightShape.roundedSquare,
    this.linkVisibility = LinkVisibility.always,
  });

  final PlayState state;
  final BoardColors colors;
  final BoardTextCache cache;
  final String fontFamily;
  final NoteHighlightShape noteHighlightShape;
  final LinkVisibility linkVisibility;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cellW = w / 9;
    final cellH = h / 9;
    final t = Tables.instance;
    final values = state.values;
    final conflicts = conflictsOf(values);
    final selected = state.selected;
    final noteFilter = state.noteCountFilter;
    // Color slot per highlighted digit, -1 when a digit is not highlighted.
    final slotOf = List<int>.filled(10, -1);
    for (var i = 0; i < state.highlightSlots.length; i++) {
      final d = state.highlightSlots[i];
      if (d != 0) slotOf[d] = i;
    }
    final slots = colors.digitSlots;
    // Cells on a strong fill (filter or paint); their marks use the given
    // color so they stay readable.
    final strongFill = List<bool>.filled(81, false);
    final cellColors = state.cellColors;
    final noteColors = state.noteColors;
    final selRow = selected == null ? -1 : t.rowOf[selected];
    final selCol = selected == null ? -1 : t.colOf[selected];
    final selBox = selected == null ? -1 : t.boxOf[selected];

    const radius = Radius.circular(kBoardCornerRadius);
    final outer = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), radius);
    canvas.save();
    canvas.clipRRect(outer);

    final fill = Paint()..style = PaintingStyle.fill;
    fill.color = colors.cell;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), fill);

    for (var i = 0; i < 81; i++) {
      final r = t.rowOf[i];
      final c = t.colOf[i];
      Color? color;
      if (i == selected) {
        continue; // drawn as a rounded tile after the grid lines
      } else if (conflicts[i] != 0) {
        color = colors.conflictCell;
      } else if (values[i] != 0 && slotOf[values[i]] >= 0) {
        color = slots[slotOf[values[i]] % slots.length].fill;
      } else if (cellColors[i] != 0) {
        // The player's own paint outranks the transient filter and peer
        // tints; the marks on it switch to the given color.
        strongFill[i] = true;
        color = slots[(cellColors[i] - 1) % slots.length].fill;
      } else if (noteFilter != 0 &&
          values[i] == 0 &&
          noteFilter & (1 << t.popcount[state.notes[i]]) != 0) {
        // Candidate-count filter: a plain cell fill, like a digit
        // highlight; the marks on it switch to the given color.
        strongFill[i] = true;
        color = t.popcount[state.notes[i]] == 2
            ? colors.twoNotesTile
            : colors.threeNotesTile;
      } else if (r == selRow || c == selCol || t.boxOf[i] == selBox) {
        color = colors.peer;
      }
      if (color == null) continue;
      fill.color = color;
      canvas.drawRect(Rect.fromLTWH(c * cellW, r * cellH, cellW, cellH), fill);
    }

    final thin = Paint()
      ..color = colors.lineThin
      ..strokeWidth = kThinLineWidth;
    final thick = Paint()
      ..color = colors.lineThick
      ..strokeWidth = kThickLineWidth;
    // Thin lines first, thick box lines on top, so crossings never show a
    // thin line over a thick one.
    for (var k = 1; k < 9; k++) {
      if (k % 3 == 0) continue;
      canvas.drawLine(Offset(k * cellW, 0), Offset(k * cellW, h), thin);
      canvas.drawLine(Offset(0, k * cellH), Offset(w, k * cellH), thin);
    }
    for (var k = 3; k < 9; k += 3) {
      canvas.drawLine(Offset(k * cellW, 0), Offset(k * cellW, h), thick);
      canvas.drawLine(Offset(0, k * cellH), Offset(w, k * cellH), thick);
    }
    canvas.restore();

    final half = kOuterLineWidth / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(half, half, w - kOuterLineWidth, h - kOuterLineWidth),
        radius,
      ),
      Paint()
        ..color = colors.lineThick
        ..style = PaintingStyle.stroke
        ..strokeWidth = kOuterLineWidth,
    );

    if (selected != null) {
      final r = t.rowOf[selected];
      final c = t.colOf[selected];
      const o = kSelectionOverflow;
      final tile = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          c * cellW - o,
          r * cellH - o,
          cellW + 2 * o,
          cellH + 2 * o,
        ),
        const Radius.circular(kSelectionRadius),
      );
      canvas.drawRRect(tile, Paint()..color = colors.selected);
      canvas.drawRRect(
        tile,
        Paint()
          ..color = colors.entry
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    final notes = state.notes;

    // Which marks sit on a link chip: 2 strong, 1 weak, 0 none.
    final linkEnd = Uint8List(81 * 9);
    _paintLinks(canvas, Size(w, h), linkEnd);

    final insetX = cellW * kNoteInset;
    final insetY = cellH * kNoteInset;
    final subW = (cellW - insetX * 2) / 3;
    final subH = (cellH - insetY * 2) / 3;
    for (var i = 0; i < 81; i++) {
      final r = t.rowOf[i];
      final c = t.colOf[i];
      final v = values[i];
      if (v != 0) {
        final style = state.isGiven(i)
            ? DigitStyle.given
            : conflicts[i] != 0
            ? DigitStyle.conflict
            : DigitStyle.entry;
        final tp = cache.digit(
          digit: v,
          style: style,
          cell: cellW,
          colors: colors,
          fontFamily: fontFamily,
        );
        paintDigit(
          canvas,
          tp,
          cellW * kDigitScale,
          c * cellW,
          r * cellH,
          cellW,
          cellH,
        );
        continue;
      }
      final mask = notes[i];
      if (mask == 0) continue;
      // Chip color slot per mark: the player's paint first, then the digit
      // highlight; -1 for a plain mark. Also a mask of lit marks for the
      // chip corners.
      final chipSlot = List<int>.filled(10, -1);
      var litMask = 0;
      for (var d = 1; d <= 9; d++) {
        if (mask & (1 << (d - 1)) == 0) continue;
        final paint = noteColors[i * 9 + d - 1];
        final slot = paint != 0
            ? (paint - 1) % slots.length
            : slotOf[d] < 0
            ? -1
            : slotOf[d] % slots.length;
        chipSlot[d] = slot;
        if (slot >= 0) litMask |= 1 << (d - 1);
      }
      for (var d = 1; d <= 9; d++) {
        if (mask & (1 << (d - 1)) == 0) continue;
        final nr = (d - 1) ~/ 3;
        final nc = (d - 1) % 3;
        final onLink = linkEnd[i * 9 + d - 1];
        final slot = chipSlot[d];
        final lit = slot >= 0 && onLink == 0; // a link chip wins the slot
        if (lit) {
          final box = Rect.fromLTWH(
            c * cellW + insetX + nc * subW,
            r * cellH + insetY + nr * subH,
            subW,
            subH,
          );
          final shapePaint = Paint()..color = slots[slot].chip;
          switch (noteHighlightShape) {
            case NoteHighlightShape.circle:
              canvas.drawCircle(box.center, box.shortestSide / 2, shapePaint);
            case NoteHighlightShape.roundedSquare:
              // A corner stays round only when no lit chip touches it.
              bool litAt(int row, int col) =>
                  row >= 0 &&
                  row < 3 &&
                  col >= 0 &&
                  col < 3 &&
                  litMask & (1 << (row * 3 + col)) != 0;
              final up = litAt(nr - 1, nc);
              final down = litAt(nr + 1, nc);
              final left = litAt(nr, nc - 1);
              final right = litAt(nr, nc + 1);
              const round = Radius.circular(kNoteChipRadius);
              canvas.drawRRect(
                RRect.fromRectAndCorners(
                  box,
                  topLeft: up || left ? Radius.zero : round,
                  topRight: up || right ? Radius.zero : round,
                  bottomLeft: down || left ? Radius.zero : round,
                  bottomRight: down || right ? Radius.zero : round,
                ),
                shapePaint,
              );
          }
        }
        final tp = cache.digit(
          digit: d,
          style: onLink == 2
              ? DigitStyle.onStrongLink
              : onLink == 1
              ? DigitStyle.onWeakLink
              : lit
              ? DigitStyle.noteHighlighted
              : i == selected || strongFill[i]
              ? DigitStyle.noteOnSelected
              : r == selRow || c == selCol || t.boxOf[i] == selBox
              ? DigitStyle.noteOnPeer
              : DigitStyle.note,
          cell: cellW,
          colors: colors,
          fontFamily: fontFamily,
          slot: lit ? slot : 0,
        );
        paintDigit(
          canvas,
          tp,
          cellW * kNoteScale,
          c * cellW + insetX + nc * subW,
          r * cellH + insetY + nr * subH,
          subW,
          subH,
        );
      }
    }
  }

  /// Links between pencil marks, under the marks and above the fills:
  /// strong solid, weak dashed, a handle halfway, a solid chip on each end
  /// and a haloed chip on the mark the next link starts from. Fills
  /// [linkEnd] (2 strong, 1 weak, 0 none per mark) for the digit pass.
  void _paintLinks(Canvas canvas, Size size, Uint8List linkEnd) {
    final start = state.linkStart;
    if (state.links.isEmpty && !(state.linkArmed && start != null)) return;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = kLinkWidth
      ..strokeCap = StrokeCap.round;
    final fill = Paint();
    for (final link in state.links) {
      if (!linkShown(state, link, linkVisibility)) continue;
      final color = link.strong ? colors.linkStrong : colors.linkWeak;
      final path = _trimmed(linkPath(link, size));
      stroke.color = color;
      canvas.drawPath(link.strong ? path : _dashed(path), stroke);
      fill.color = color;
      canvas.drawCircle(linkHandle(link, size), kLinkHandleRadius, fill);
      final kind = link.strong ? 2 : 1;
      for (final (cell, digit) in [
        (link.cellA, link.digitA),
        (link.cellB, link.digitB),
      ]) {
        final at = cell * 9 + digit - 1;
        if (linkEnd[at] < kind) linkEnd[at] = kind; // strong wins the chip
      }
    }
    if (state.linkArmed && start != null) {
      linkEnd[start.cell * 9 + start.digit - 1] = 2;
      // The start is unmistakable: a halo past its chip.
      fill.color = colors.linkStrong.withValues(alpha: 0.35);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          noteBox(start.cell, start.digit, size).inflate(kLinkStartHalo),
          const Radius.circular(kLinkChipRadius + kLinkStartHalo),
        ),
        fill,
      );
    }
    for (var at = 0; at < linkEnd.length; at++) {
      if (linkEnd[at] == 0) continue;
      fill.color = linkEnd[at] == 2 ? colors.linkStrong : colors.linkWeak;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          noteBox(at ~/ 9, at % 9 + 1, size).deflate(0.4),
          const Radius.circular(kLinkChipRadius),
        ),
        fill,
      );
    }
  }

  static Path _trimmed(Path path) {
    final out = Path();
    for (final metric in path.computeMetrics()) {
      final trim = kLinkEndTrim < (metric.length - 2) / 2
          ? kLinkEndTrim
          : (metric.length - 2) / 2;
      if (trim <= 0) continue;
      out.addPath(metric.extractPath(trim, metric.length - trim), Offset.zero);
    }
    return out;
  }

  static Path _dashed(Path path) {
    final out = Path();
    for (final metric in path.computeMetrics()) {
      var at = 0.0;
      while (at < metric.length) {
        final end = (at + kLinkDashOn).clamp(0.0, metric.length);
        out.addPath(metric.extractPath(at, end), Offset.zero);
        at = end + kLinkDashOff;
      }
    }
    return out;
  }

  @override
  bool shouldRepaint(BoardPainter oldDelegate) {
    return !identical(oldDelegate.state, state) ||
        oldDelegate.colors != colors ||
        oldDelegate.fontFamily != fontFamily ||
        oldDelegate.noteHighlightShape != noteHighlightShape ||
        oldDelegate.linkVisibility != linkVisibility;
  }
}
