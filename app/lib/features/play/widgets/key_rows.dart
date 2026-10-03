import 'package:flutter/material.dart';

import '../../settings/app_settings.dart';

/// Nine keys laid out the way the keypad setting says: one row, or two
/// rows (1-5 above 6-9) with the lower row offset by half a key, like a
/// keyboard. Shared by the digit keypad and the paint palette so both
/// have the same size and rhythm.
class KeyRows extends StatelessWidget {
  const KeyRows({
    super.key,
    required this.layout,
    required this.builder,
    this.rowGap = gap,
  });

  final NumberPadLayout layout;

  /// Builds the key for position 1..9.
  final Widget Function(int index) builder;

  /// Space between the two rows; scaled down with the keys when squeezed.
  final double rowGap;

  static const double gap = 4;

  /// Widest a key gets in the two-row layout; rows are centered below that.
  static const double maxKeyWidth = 58;

  @override
  Widget build(BuildContext context) {
    return switch (layout) {
      NumberPadLayout.oneRow => Row(
        children: [
          for (var d = 1; d <= 9; d++) ...[
            if (d > 1) const SizedBox(width: gap),
            Expanded(child: builder(d)),
          ],
        ],
      ),
      NumberPadLayout.twoRows => LayoutBuilder(
        builder: (context, constraints) {
          final available = (constraints.maxWidth - gap * 4) / 5;
          final keyWidth = available < maxKeyWidth ? available : maxKeyWidth;
          final offset = (keyWidth + gap) / 2;
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var d = 1; d <= 5; d++) ...[
                    if (d > 1) const SizedBox(width: gap),
                    SizedBox(width: keyWidth, child: builder(d)),
                  ],
                ],
              ),
              SizedBox(height: rowGap),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: offset),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var d = 6; d <= 9; d++) ...[
                      if (d > 6) const SizedBox(width: gap),
                      SizedBox(width: keyWidth, child: builder(d)),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    };
  }
}
