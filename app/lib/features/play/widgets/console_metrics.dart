import '../../settings/app_settings.dart';
import 'board_painter.dart';
import 'number_pad.dart';
import 'play_toolbar.dart';

/// How the console below the board (toolbar, palette, keypad) fits the
/// screen. The board always keeps its full width; when the height left
/// under it is short, as on phones with large safe areas, the console
/// shrinks by [scale] instead, and on very short screens the keypad
/// drops to one row before the controls get too small to use.
class ConsoleMetrics {
  const ConsoleMetrics({
    required this.scale,
    required this.layout,
    required this.reserveOneRow,
  });

  /// Multiplier on every vertical size of the console, 1 when it fits.
  final double scale;

  /// Keypad layout actually shown: the setting, or one row when forced.
  final NumberPadLayout layout;

  /// Whether a one-row keypad keeps the two-row height below it, so the
  /// board sits at the same height in both layouts. Dropped when short.
  final bool reserveOneRow;

  static const double topRow = 48;
  static const double topGap = 8;
  static const double boardInset = 6;
  static const double boardGap = 12;
  static const double toolbarGap = 8;
  static const double bottomPad = 12;

  /// Smallest the console goes; below this the board gives way after all.
  static const double minScale = 0.6;

  /// A two-row keypad that would shrink past this becomes one row.
  static const double oneRowBelow = 0.68;

  static double naturalHeight(
    NumberPadLayout layout, {
    required bool reserve,
  }) =>
      boardGap +
      PlayToolbar.naturalHeight +
      toolbarGap +
      NumberPad.naturalHeight(layout, reserve: reserve) +
      bottomPad;

  static ConsoleMetrics fit({
    required double width,
    required double height,
    required NumberPadLayout layout,
  }) {
    final boardHeight = (width - 2 * boardInset) / kBoardAspectRatio;
    final available = height - topRow - topGap - boardHeight;
    if (available >= naturalHeight(layout, reserve: true)) {
      return ConsoleMetrics(scale: 1, layout: layout, reserveOneRow: true);
    }
    var shown = layout;
    var scale = available / naturalHeight(shown, reserve: false);
    if (scale < oneRowBelow && shown == NumberPadLayout.twoRows) {
      shown = NumberPadLayout.oneRow;
      scale = available / naturalHeight(shown, reserve: false);
    }
    return ConsoleMetrics(
      scale: scale.clamp(minScale, 1.0),
      layout: shown,
      reserveOneRow: false,
    );
  }
}
