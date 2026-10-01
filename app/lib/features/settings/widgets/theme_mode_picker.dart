import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/color_theme.dart';

/// Three preview tiles: system, light, dark. Each shows a miniature board in
/// the palette it would apply.
class ThemeModePicker extends StatelessWidget {
  const ThemeModePicker({
    super.key,
    required this.value,
    required this.colorTheme,
    required this.onChanged,
  });

  final ThemeMode value;
  final ColorTheme colorTheme;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final mode in ThemeMode.values) ...[
          if (mode != ThemeMode.values.first) const SizedBox(width: 10),
          Expanded(
            child: _ThemeTile(
              mode: mode,
              colorTheme: colorTheme,
              selected: mode == value,
              onTap: () => onChanged(mode),
            ),
          ),
        ],
      ],
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.mode,
    required this.colorTheme,
    required this.selected,
    required this.onTap,
  });

  final ThemeMode mode;
  final ColorTheme colorTheme;
  final bool selected;
  final VoidCallback onTap;

  static const _labels = {
    ThemeMode.system: '시스템',
    ThemeMode.light: '라이트',
    ThemeMode.dark: '다크',
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final border = selected ? scheme.primary : scheme.outlineVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: _labels[mode],
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border, width: selected ? 2 : 1),
              ),
              padding: const EdgeInsets.all(4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: CustomPaint(
                    painter: _PreviewPainter(mode: mode, theme: colorTheme),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _labels[mode]!,
              style: text.bodyMedium?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? scheme.primary : scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints a 3×3 mini board. The system tile is split diagonally between the
/// light and dark palettes.
class _PreviewPainter extends CustomPainter {
  const _PreviewPainter({required this.mode, required this.theme});

  final ThemeMode mode;
  final ColorTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    switch (mode) {
      case ThemeMode.light:
        _paintBoard(canvas, size, Brightness.light);
      case ThemeMode.dark:
        _paintBoard(canvas, size, Brightness.dark);
      case ThemeMode.system:
        _paintBoard(canvas, size, Brightness.light);
        canvas.save();
        canvas.clipPath(
          Path()
            ..moveTo(rect.right, rect.top)
            ..lineTo(rect.right, rect.bottom)
            ..lineTo(rect.left, rect.bottom)
            ..close(),
        );
        _paintBoard(canvas, size, Brightness.dark);
        canvas.restore();
    }
  }

  void _paintBoard(Canvas canvas, Size size, Brightness brightness) {
    final colors = theme.board(brightness);
    final scaffold = theme.scaffold(brightness);
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = scaffold);

    final inset = size.width * 0.14;
    final board = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    final cell = board.width / 3;
    canvas.drawRect(board, Paint()..color = colors.cell);

    void fill(int r, int c, Color color) {
      canvas.drawRect(
        Rect.fromLTWH(board.left + c * cell, board.top + r * cell, cell, cell),
        Paint()..color = color,
      );
    }

    fill(0, 1, colors.peer);
    fill(2, 1, colors.peer);
    fill(1, 0, colors.peer);
    fill(1, 2, colors.peer);
    fill(1, 1, colors.selected);

    final line = Paint()
      ..color = colors.lineThin
      ..strokeWidth = 1;
    for (var k = 1; k < 3; k++) {
      final x = board.left + k * cell;
      final y = board.top + k * cell;
      canvas.drawLine(Offset(x, board.top), Offset(x, board.bottom), line);
      canvas.drawLine(Offset(board.left, y), Offset(board.right, y), line);
    }
    canvas.drawRect(
      board,
      Paint()
        ..color = colors.lineThick
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    _digit(canvas, board, cell, 0, 0, '5', colors.given, FontWeight.w700);
    _digit(canvas, board, cell, 1, 1, '3', colors.entry, FontWeight.w500);
    _digit(canvas, board, cell, 2, 2, '8', colors.given, FontWeight.w700);
  }

  void _digit(
    Canvas canvas,
    Rect board,
    double cell,
    int r,
    int c,
    String text,
    Color color,
    FontWeight weight,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: cell * 0.56,
          fontWeight: weight,
          fontFamily: AppTheme.fontFamily,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(
        board.left + c * cell + (cell - painter.width) / 2,
        board.top + r * cell + (cell - painter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(_PreviewPainter oldDelegate) =>
      oldDelegate.mode != mode || oldDelegate.theme != theme;
}
