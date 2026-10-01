import 'package:flutter/material.dart';

import '../../../core/theme/board_colors.dart';
import 'board_painter.dart' show kDigitCapHeight, kDigitScale, kNoteScale;

/// Top-left offset that centers [painter]'s digit glyph in a box of
/// [width]×[height] whose top-left corner is ([left], [top]).
Offset centerDigit(
  TextPainter painter,
  double fontSize,
  double left,
  double top,
  double width,
  double height,
) {
  final baseline = painter.computeDistanceToActualBaseline(
    TextBaseline.alphabetic,
  );
  final glyphCenter = baseline - fontSize * kDigitCapHeight / 2;
  return Offset(
    left + (width - painter.width) / 2,
    top + height / 2 - glyphCenter,
  );
}

/// Paints [painter] with its glyph centered in the given box.
void paintDigit(
  Canvas canvas,
  TextPainter painter,
  double fontSize,
  double left,
  double top,
  double width,
  double height,
) {
  painter.paint(
    canvas,
    centerDigit(painter, fontSize, left, top, width, height),
  );
}

/// Caches laid-out digits so a frame never lays out 81 text runs.
class BoardTextCache {
  final Map<int, TextPainter> _painters = {};
  double _cell = -1;
  BoardColors? _colors;
  String? _fontFamily;

  /// [slot] picks the chip text color for [DigitStyle.noteHighlighted].
  TextPainter digit({
    required int digit,
    required DigitStyle style,
    required double cell,
    required BoardColors colors,
    required String fontFamily,
    int slot = 0,
  }) {
    if (cell != _cell || colors != _colors || fontFamily != _fontFamily) {
      _painters.clear();
      _cell = cell;
      _colors = colors;
      _fontFamily = fontFamily;
    }
    final key = (style.index * 10 + digit) * 8 + slot;
    return _painters.putIfAbsent(key, () {
      final textStyle = switch (style) {
        DigitStyle.given => TextStyle(
          color: colors.given,
          fontWeight: FontWeight.w500,
          fontSize: cell * kDigitScale,
        ),
        DigitStyle.entry => TextStyle(
          color: colors.entry,
          fontWeight: FontWeight.w400,
          fontSize: cell * kDigitScale,
        ),
        DigitStyle.conflict => TextStyle(
          color: colors.conflictText,
          fontWeight: FontWeight.w400,
          fontSize: cell * kDigitScale,
        ),
        DigitStyle.note => TextStyle(
          color: colors.note,
          fontWeight: FontWeight.w400,
          fontSize: cell * kNoteScale,
        ),
        DigitStyle.noteOnSelected => TextStyle(
          color: colors.given,
          fontWeight: FontWeight.w400,
          fontSize: cell * kNoteScale,
        ),
        DigitStyle.noteOnPeer => TextStyle(
          color: colors.noteOnPeer,
          fontWeight: FontWeight.w400,
          fontSize: cell * kNoteScale,
        ),
        DigitStyle.onStrongLink => TextStyle(
          color: colors.linkStrongText,
          fontWeight: FontWeight.w600,
          fontSize: cell * kNoteScale,
        ),
        DigitStyle.onWeakLink => TextStyle(
          color: colors.linkWeakText,
          fontWeight: FontWeight.w600,
          fontSize: cell * kNoteScale,
        ),
        DigitStyle.noteHighlighted => TextStyle(
          color: colors.digitSlots[slot].chipText,
          fontWeight: FontWeight.w500,
          fontSize: cell * kNoteScale,
        ),
      };
      return TextPainter(
        text: TextSpan(
          text: '$digit',
          style: textStyle.copyWith(
            fontFamily: fontFamily,
            fontFeatures: const [FontFeature.tabularFigures()],
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    });
  }
}

/// Which text style a digit is drawn with.
enum DigitStyle {
  given,
  entry,
  conflict,
  note,
  noteOnSelected,
  noteOnPeer,
  noteHighlighted,
  onStrongLink,
  onWeakLink,
}
