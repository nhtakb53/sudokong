import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Hand-drawn 24-unit glyphs for tools the Material icon font lacks. Both
/// are drawn with the font's 2-unit round stroke so they sit next to its
/// icons without looking foreign. [filled] shades one section, which is
/// how the toolbar shows an armed tool.
class EraserIcon extends StatelessWidget {
  const EraserIcon({
    super.key,
    required this.color,
    this.filled = false,
    this.size = 24,
  });

  final Color color;
  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _EraserPainter(color, filled),
  );
}

class PencilIcon extends StatelessWidget {
  const PencilIcon({
    super.key,
    required this.color,
    this.filled = false,
    this.size = 24,
  });

  final Color color;
  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _PencilPainter(color, filled),
  );
}

abstract class _GlyphPainter extends CustomPainter {
  const _GlyphPainter(this.color, this.filled);

  final Color color;
  final bool filled;

  Paint get stroke => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  Paint get fill => Paint()..color = color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    draw(canvas);
  }

  void draw(Canvas canvas);

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.color != color || old.filled != filled;
}

/// A block eraser standing on its baseline, leaning to the right, with
/// the band that meets the paper marked off. Armed: the band is shaded.
class _EraserPainter extends _GlyphPainter {
  const _EraserPainter(super.color, super.filled);

  @override
  void draw(Canvas canvas) {
    final body = Path()
      ..moveTo(7, 21)
      ..lineTo(2.7, 16.7)
      ..relativeCubicTo(-1, -1, -1, -2.5, 0, -3.4)
      ..relativeLineTo(9.6, -9.6)
      ..relativeCubicTo(1, -1, 2.5, -1, 3.4, 0)
      ..relativeLineTo(5.6, 5.6)
      ..relativeCubicTo(1, 1, 1, 2.5, 0, 3.4)
      ..lineTo(13, 21)
      ..close();
    if (filled) {
      // Everything on the paper side of the divider.
      final paperSide = Path()
        ..moveTo(5, 11)
        ..lineTo(14, 20)
        ..lineTo(-16, 50)
        ..lineTo(-25, 41)
        ..close();
      canvas.drawPath(
        Path.combine(PathOperation.intersect, body, paperSide),
        fill,
      );
    }
    canvas.drawPath(body, stroke);
    canvas.drawLine(const Offset(5, 11), const Offset(14, 20), stroke);
    canvas.drawLine(const Offset(7, 21), const Offset(22, 21), stroke);
  }
}

/// A pencil pointing down-left: lead, wood, painted body, ferrule and
/// eraser cap. Armed: the painted body is shaded.
class _PencilPainter extends _GlyphPainter {
  const _PencilPainter(super.color, super.filled);

  @override
  void draw(Canvas canvas) {
    canvas
      ..translate(12, 12)
      ..rotate(-math.pi / 4);
    // Along the axis: tip -10.5, wood line -5.5, ferrule 7.5, cap end 10.5.
    final outline = Path()
      ..moveTo(-10.5, 0)
      ..lineTo(-5.5, -3)
      ..lineTo(9, -3)
      ..arcToPoint(const Offset(10.5, -1.5), radius: const Radius.circular(1.5))
      ..lineTo(10.5, 1.5)
      ..arcToPoint(const Offset(9, 3), radius: const Radius.circular(1.5))
      ..lineTo(-5.5, 3)
      ..close();
    if (filled) {
      canvas.drawRect(const Rect.fromLTRB(-5.5, -3, 7.5, 3), fill);
    }
    canvas
      ..drawPath(outline, stroke)
      ..drawLine(const Offset(-5.5, -3), const Offset(-5.5, 3), stroke)
      ..drawLine(const Offset(7.5, -3), const Offset(7.5, 3), stroke);
  }
}
