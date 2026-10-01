import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../model/play_intent.dart';
import '../model/play_state.dart';
import '../../settings/settings_provider.dart';
import '../play_controller.dart';
import 'board_painter.dart';
import 'board_text_cache.dart';

/// The 9×9 board: one canvas plus a tap layer.
class BoardView extends ConsumerStatefulWidget {
  const BoardView({super.key, required this.state});

  final PlayState state;

  @override
  ConsumerState<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends ConsumerState<BoardView> {
  final _cache = BoardTextCache();

  int _cellAt(Offset position, Size size) {
    final col = (position.dx ~/ (size.width / 9)).clamp(0, 8);
    final row = (position.dy ~/ (size.height / 9)).clamp(0, 8);
    return row * 9 + col;
  }

  /// The pencil mark of [index] nearest to [position], or null when the
  /// cell has none.
  int? _nearestNote(int index, Offset position, Size size) {
    final state = widget.state;
    final mask = state.notes[index];
    if (state.values[index] != 0 || mask == 0) return null;
    final cellW = size.width / 9;
    final cellH = size.height / 9;
    final left = (index % 9) * cellW + cellW * kNoteInset;
    final top = (index ~/ 9) * cellH + cellH * kNoteInset;
    final subW = (cellW - 2 * cellW * kNoteInset) / 3;
    final subH = (cellH - 2 * cellH * kNoteInset) / 3;
    int? best;
    var bestDistance = double.infinity;
    for (var d = 1; d <= 9; d++) {
      if (mask & (1 << (d - 1)) == 0) continue;
      final center = Offset(
        left + ((d - 1) % 3 + 0.5) * subW,
        top + ((d - 1) ~/ 3 + 0.5) * subH,
      );
      final distance = (position - center).distanceSquared;
      if (distance < bestDistance) {
        bestDistance = distance;
        best = d;
      }
    }
    return best;
  }

  void _paint(Offset position, Size size, PaintTarget target) {
    final controller = ref.read(playControllerProvider.notifier);
    final index = _cellAt(position, size);
    switch (target) {
      case PaintTarget.cell:
        HapticFeedback.selectionClick();
        controller.dispatch(PaintCell(index));
      case PaintTarget.note:
        final digit = _nearestNote(index, position, size);
        if (digit == null) return;
        HapticFeedback.selectionClick();
        controller.dispatch(PaintNote(index, digit));
    }
  }

  /// With a color armed a tap paints; otherwise it selects.
  void _onTap(Offset position, Size size) {
    final state = widget.state;
    if (state.paintArmed) return _paint(position, size, state.paintTarget);
    ref
        .read(playControllerProvider.notifier)
        .dispatch(SelectCell(_cellAt(position, size)));
  }

  /// With a color armed a long press always paints the nearest pencil
  /// mark, so single marks can be colored without switching the target.
  void _onLongPress(Offset position, Size size) {
    if (widget.state.paintArmed) {
      return _paint(position, size, PaintTarget.note);
    }
    HapticFeedback.mediumImpact();
    ref
        .read(playControllerProvider.notifier)
        .dispatch(PlaceAt(_cellAt(position, size)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.boardColors;
    final shape = ref.watch(
      settingsProvider.select((s) => s.noteHighlightShape),
    );
    final longPress = ref.watch(settingsProvider.select((s) => s.longPress));
    return AspectRatio(
      aspectRatio: kBoardAspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          return RawGestureDetector(
            behavior: HitTestBehavior.opaque,
            gestures: {
              TapGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                    TapGestureRecognizer.new,
                    (r) => r.onTapDown = (d) => _onTap(d.localPosition, size),
                  ),
              LongPressGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<
                    LongPressGestureRecognizer
                  >(
                    () => LongPressGestureRecognizer(duration: longPress),
                    (r) =>
                        r.onLongPressStart = (d) =>
                            _onLongPress(d.localPosition, size),
                  ),
            },
            child: RepaintBoundary(
              child: CustomPaint(
                size: size,
                painter: BoardPainter(
                  state: widget.state,
                  colors: colors,
                  cache: _cache,
                  fontFamily: AppTheme.fontFamily,
                  noteHighlightShape: shape,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
