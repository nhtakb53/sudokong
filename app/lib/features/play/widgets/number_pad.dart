import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../settings/app_settings.dart';
import '../../settings/settings_provider.dart';
import '../model/play_intent.dart';
import '../model/play_state.dart';
import '../play_controller.dart';
import 'key_rows.dart';

/// Digit keys in the Sudoku Dojo style: plain large digits with the number
/// of placements still missing shown as a small superscript. One row, or
/// two rows with the second row offset by half a key.
class NumberPad extends ConsumerWidget {
  const NumberPad({
    super.key,
    required this.values,
    this.highlightSlots = kNoHighlights,
    this.activeDigit = 0,
    this.noteMode = false,
    this.selectedWritable = false,
    this.paintColor = -1,
  });

  /// Current board values, used for the remaining counts.
  final Uint8List values;

  /// Highlighted digit per color slot (see [PlayState.highlightSlots]);
  /// keys take the matching board color so the pad doubles as the legend.
  final List<int> highlightSlots;

  /// The armed (digit-first) or last touched digit, or 0.
  final int activeDigit;

  /// When true, a tap writes a pencil mark; keys render in note style.
  final bool noteMode;

  /// True when a non-given cell is selected, so a held key writes into it
  /// (cell-first) instead of toggling a highlight.
  final bool selectedWritable;

  /// The armed palette color (1-9), 0 for the eraser, or -1 when a digit
  /// is the tool instead. Drawn as the picked swatch in the color strip.
  final int paintColor;

  static const double keyHeight = 72;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(settingsProvider.select((s) => s.numberPadLayout));
    final longPress = ref.watch(settingsProvider.select((s) => s.longPress));
    final inputMode = ref.watch(settingsProvider.select((s) => s.inputMode));
    final holdWrites = inputMode == InputMode.cellFirst && selectedWritable;
    final multi = highlightSlots.where((d) => d != 0).length >= 2;
    final remaining = List<int>.filled(10, 9);
    for (var i = 0; i < 81; i++) {
      final v = values[i];
      if (v != 0) remaining[v]--;
    }

    final controller = ref.read(playControllerProvider.notifier);
    void tap(int digit) {
      if (noteMode) {
        HapticFeedback.selectionClick();
        controller.dispatch(EnterNote(digit));
      } else {
        HapticFeedback.lightImpact();
        controller.dispatch(EnterDigit(digit));
      }
    }

    // A held key writes the value whatever the mode when a cell can take
    // it; otherwise it adds the digit to (or drops it from) the highlight.
    void hold(int digit) {
      if (holdWrites) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
      controller.dispatch(HoldDigit(digit));
    }

    Widget key(int d) => _DigitKey(
      digit: d,
      remaining: remaining[d],
      slot: highlightSlots.indexOf(d),
      // With several digits lit, the tile alone cannot say which one a
      // digit-first tap places, so that key gets an outline.
      armed:
          inputMode == InputMode.digitFirst &&
          d == activeDigit &&
          (multi || !highlightSlots.contains(d)),
      noteStyle: noteMode,
      // A one-row key is too narrow for a superscript, so the count
      // moves under the digit there.
      countBelow: layout == NumberPadLayout.oneRow,
      longPress: longPress,
      onTap: () => tap(d),
      onLongPress: () => hold(d),
    );

    final scheme = Theme.of(context).colorScheme;
    // Two boxes: the palette above, the digit keys below where the thumb
    // rests. Note mode only recolors the digit box (the board's peer
    // tint), so the mode reads as an area change rather than a change to
    // each key.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: _PaintStrip(picked: paintColor),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: noteMode
                ? context.boardColors.peer
                : scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(18),
          ),
          child: KeyRows(layout: layout, builder: key),
        ),
        // A single row keeps its box compact but stays on the line of the
        // two-row layout's upper row, so the board and toolbar never move;
        // the saved height becomes bottom margin.
        if (layout == NumberPadLayout.oneRow)
          SizedBox(height: keyHeight + KeyRows.gap),
      ],
    );
  }
}

class _DigitKey extends StatelessWidget {
  const _DigitKey({
    required this.digit,
    required this.remaining,
    required this.slot,
    required this.armed,
    required this.noteStyle,
    required this.countBelow,
    required this.longPress,
    required this.onTap,
    required this.onLongPress,
  });

  final int digit;
  final int remaining;

  /// Highlight color slot, or -1 when the digit is not highlighted.
  final int slot;
  final bool armed;
  final bool noteStyle;
  final bool countBelow;
  final Duration longPress;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.boardColors;
    final done = remaining <= 0;
    final slots = colors.digitSlots;
    final tile = slot < 0 ? null : slots[slot % slots.length].fill;
    return Semantics(
      button: true,
      label: '$digit',
      value: done ? '완료' : '$remaining개 남음',
      // The long press has a user-set duration, so it comes from its own
      // recognizer rather than InkWell's fixed timeout.
      child: RawGestureDetector(
        gestures: {
          LongPressGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
                () => LongPressGestureRecognizer(duration: longPress),
                (r) => r.onLongPress = done ? null : onLongPress,
              ),
        },
        child: InkWell(
          key: ValueKey('numpad-$digit'),
          onTap: done ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: NumberPad.keyHeight,
            decoration: BoxDecoration(
              color: tile ?? Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: armed ? colors.entry : Colors.transparent,
                width: 2,
              ),
            ),
            child: Opacity(
              opacity: done ? 0.3 : 1,
              child: Builder(
                builder: (context) {
                  final countStyle = TextStyle(
                    // The lighter mark color on plain keys; on a colored
                    // tile the count takes the strong text color instead.
                    color: tile == null ? colors.note : colors.given,
                    fontSize: countBelow ? 12 : 13,
                    fontWeight: FontWeight.w500,
                    height: 1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  );
                  // In note mode the key keeps its size; the digits switch
                  // from entry blue to the strong given color on the tinted
                  // panel, so the mode is obvious and still crisp.
                  final digitText = Text(
                    '$digit',
                    style: TextStyle(
                      color: noteStyle ? colors.given : colors.entry,
                      fontSize: countBelow ? 32 : 36,
                      fontWeight: FontWeight.w600,
                      height: 1,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  );
                  if (countBelow) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        digitText,
                        const SizedBox(height: 5),
                        Text(done ? ' ' : '$remaining', style: countStyle),
                      ],
                    );
                  }
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      digitText,
                      if (!done)
                        Transform.translate(
                          // Top-right of the digit; the digit itself stays on
                          // the key's center.
                          offset: const Offset(17, -14),
                          child: Text('$remaining', style: countStyle),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Nine palette colors and an eraser above the digit keys. Tapping one arms
/// it, so the next board taps paint; a digit key takes over again. Holding
/// the eraser clears every painted cell and mark.
class _PaintStrip extends ConsumerWidget {
  const _PaintStrip({required this.picked});

  /// Armed color 1-9, 0 for the eraser, -1 when nothing is armed.
  final int picked;

  static const double height = 40;
  static const double gap = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(playControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final board = context.boardColors;
    final slots = board.digitSlots;
    void pick(int c) {
      HapticFeedback.selectionClick();
      controller.dispatch(PickPaint(c));
    }

    return Row(
      children: [
        for (var c = 1; c <= kPaintColors; c++) ...[
          Expanded(
            child: _Swatch(
              key: ValueKey('paint-$c'),
              label: '색 $c',
              picked: picked == c,
              fill: slots[c - 1].fill,
              mark: slots[c - 1].chip,
              outline: board.entry,
              onTap: () => pick(c),
            ),
          ),
          const SizedBox(width: gap),
        ],
        Expanded(
          child: Semantics(
            hint: '길게 누르면 색칠을 모두 지웁니다',
            child: GestureDetector(
              onLongPress: () {
                HapticFeedback.mediumImpact();
                controller.dispatch(const ClearPaint());
              },
              child: _Swatch(
                key: const ValueKey('paint-eraser'),
                label: '지우개',
                picked: picked == 0,
                fill: Colors.transparent,
                border: scheme.outlineVariant,
                outline: board.entry,
                icon: Icon(
                  Icons.format_color_reset_outlined,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
                onTap: () => pick(0),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    super.key,
    required this.label,
    required this.picked,
    required this.fill,
    required this.outline,
    required this.onTap,
    this.mark,
    this.border,
    this.icon,
  });

  final String label;
  final bool picked;
  final Color fill;
  final Color outline;
  final VoidCallback onTap;
  final Color? mark;
  final Color? border;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: picked,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: _PaintStrip.height,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: picked ? outline : (border ?? Colors.transparent),
              width: picked ? 2.5 : 1,
            ),
          ),
          child: Center(
            child:
                icon ??
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: mark,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
          ),
        ),
      ),
    );
  }
}
