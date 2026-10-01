import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudokong/core/theme/board_colors.dart';

/// WCAG relative luminance.
double _lum(Color c) {
  double f(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * f(c.r) + 0.7152 * f(c.g) + 0.0722 * f(c.b);
}

double contrast(Color a, Color b) {
  final la = _lum(a);
  final lb = _lum(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  for (final entry in {
    'light': BoardColors.light,
    'dark': BoardColors.dark,
  }.entries) {
    final c = entry.value;
    group('${entry.key} palette legibility', () {
      test('pencil marks read where they live: plain cells and peers', () {
        for (final bg in [c.cell, c.peer]) {
          expect(
            contrast(c.note, bg),
            greaterThanOrEqualTo(4.5),
            reason: 'note on $bg',
          );
        }
        // Keypad digits in note mode are large text on a lit key.
        expect(contrast(c.note, c.sameDigit), greaterThanOrEqualTo(3.0));
        // Inside the peer band marks step up a shade and read clearly.
        expect(contrast(c.noteOnPeer, c.peer), greaterThanOrEqualTo(6.0));
      });

      test('givens and marks are told apart by brightness', () {
        // Entries differ from both by hue (blue), so only this pair needs
        // a brightness gap.
        expect(contrast(c.given, c.note), greaterThanOrEqualTo(2.0));
      });

      test('pencil marks in the selected cell use the given color', () {
        expect(contrast(c.given, c.selected), greaterThanOrEqualTo(4.5));
      });

      test('highlighted pencil mark chip is readable and visible', () {
        expect(
          contrast(c.noteHighlightText, c.noteHighlightFill),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(c.noteHighlightFill, c.cell),
          greaterThanOrEqualTo(3.0),
        );
        expect(
          contrast(c.noteHighlightFill, c.selected),
          greaterThanOrEqualTo(3.0),
        );
      });

      test('candidate-count tiles stand out and keep marks readable', () {
        for (final tile in [c.twoNotesTile, c.threeNotesTile]) {
          // Marks on a tile are drawn in the given color.
          expect(contrast(c.given, tile), greaterThanOrEqualTo(4.5));
          expect(contrast(tile, c.cell), greaterThanOrEqualTo(1.25));
          // Against the peer band the hue does most of the work.
          expect(contrast(tile, c.peer), greaterThanOrEqualTo(1.1));
        }
      });

      test('every extra highlight color reads and stands apart', () {
        for (final slot in c.extraSlots) {
          // Marks never sit on a digit fill; the keypad count there uses
          // the given color.
          expect(contrast(c.given, slot.fill), greaterThanOrEqualTo(4.5));
          expect(contrast(c.entry, slot.fill), greaterThanOrEqualTo(3.0));
          expect(contrast(slot.fill, c.cell), greaterThanOrEqualTo(1.2));
          expect(contrast(slot.chipText, slot.chip), greaterThanOrEqualTo(4.5));
          expect(contrast(slot.chip, c.cell), greaterThanOrEqualTo(1.8));
        }
      });

      test('main digits read on every fill', () {
        for (final bg in [c.cell, c.peer, c.sameDigit, c.selected]) {
          expect(
            contrast(c.given, bg),
            greaterThanOrEqualTo(4.5),
            reason: 'given on $bg',
          );
          expect(
            contrast(c.entry, bg),
            greaterThanOrEqualTo(3.0),
            reason: 'entry on $bg',
          );
        }
      });
    });
  }
}
