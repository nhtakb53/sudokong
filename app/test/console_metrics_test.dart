import 'package:flutter_test/flutter_test.dart';
import 'package:sudokong/features/play/widgets/console_metrics.dart';
import 'package:sudokong/features/settings/app_settings.dart';

void main() {
  test('a tall screen keeps the console at full size', () {
    // Galaxy S23 with the bars hidden.
    final m = ConsoleMetrics.fit(
      width: 393,
      height: 851,
      layout: NumberPadLayout.twoRows,
    );
    expect(m.scale, 1);
    expect(m.layout, NumberPadLayout.twoRows);
    expect(m.reserveOneRow, isTrue);
  });

  test(
    'an iPhone with large safe areas shrinks the console, not the board',
    () {
      // iPhone 15: 852 minus the 59 top and 34 bottom insets.
      final m = ConsoleMetrics.fit(
        width: 393,
        height: 852 - 59 - 34,
        layout: NumberPadLayout.twoRows,
      );
      expect(m.layout, NumberPadLayout.twoRows);
      expect(m.scale, closeTo(0.8, 0.03));
      final used =
          ConsoleMetrics.topRow +
          ConsoleMetrics.topGap +
          (393 - 2 * ConsoleMetrics.boardInset) * 1.08 +
          ConsoleMetrics.naturalHeight(m.layout, reserve: false) * m.scale;
      expect(used, closeTo(852 - 59 - 34, 0.5));
    },
  );

  test('a very short screen drops the keypad to one row first', () {
    // iPhone SE (3rd gen) below its status bar.
    final m = ConsoleMetrics.fit(
      width: 375,
      height: 667 - 20,
      layout: NumberPadLayout.twoRows,
    );
    expect(m.layout, NumberPadLayout.oneRow);
    expect(m.scale, greaterThanOrEqualTo(ConsoleMetrics.minScale));
    expect(m.scale, lessThan(1));
  });

  test('a one-row keypad gives up its spare height before shrinking', () {
    final m = ConsoleMetrics.fit(
      width: 393,
      height: 800,
      layout: NumberPadLayout.oneRow,
    );
    expect(m.layout, NumberPadLayout.oneRow);
    expect(m.scale, 1);
    expect(m.reserveOneRow, isFalse);
  });
}
