import 'dart:ui';

import '../../settings/app_settings.dart';
import '../model/play_state.dart';
import 'board_painter.dart' show kNoteInset;

/// Center of pencil mark [digit] in [cell] on a board of [size].
Offset noteCenter(int cell, int digit, Size size) =>
    noteBox(cell, digit, size).center;

/// The 3×3 slot of pencil mark [digit] in [cell].
Rect noteBox(int cell, int digit, Size size) {
  final cellW = size.width / 9;
  final cellH = size.height / 9;
  final insetX = cellW * kNoteInset;
  final insetY = cellH * kNoteInset;
  final subW = (cellW - 2 * insetX) / 3;
  final subH = (cellH - 2 * insetY) / 3;
  return Rect.fromLTWH(
    (cell % 9) * cellW + insetX + ((digit - 1) % 3) * subW,
    (cell ~/ 9) * cellH + insetY + ((digit - 1) ~/ 3) * subH,
    subW,
    subH,
  );
}

/// Control point of a link's curve from [a] to [b]: straight inside one
/// cell, otherwise bowed sideways so the curve clears marks in between.
Offset linkControl(Offset a, Offset b, {required bool sameCell}) {
  final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
  if (sameCell) return mid;
  final d = b - a;
  final len = d.distance;
  if (len == 0) return mid;
  final normal = Offset(-d.dy / len, d.dx / len);
  // A quadratic curve passes at half its control offset: 12% of the span.
  return mid + normal * (len * 0.24);
}

/// The curve of [link] on a board of [size].
Path linkPath(NoteLink link, Size size) {
  final a = noteCenter(link.cellA, link.digitA, size);
  final b = noteCenter(link.cellB, link.digitB, size);
  final c = linkControl(a, b, sameCell: link.cellA == link.cellB);
  return Path()
    ..moveTo(a.dx, a.dy)
    ..quadraticBezierTo(c.dx, c.dy, b.dx, b.dy);
}

/// Where the strong/weak handle of [link] sits: halfway along its curve.
Offset linkHandle(NoteLink link, Size size) {
  final a = noteCenter(link.cellA, link.digitA, size);
  final b = noteCenter(link.cellB, link.digitB, size);
  final c = linkControl(a, b, sameCell: link.cellA == link.cellB);
  return a * 0.25 + c * 0.5 + b * 0.25;
}

/// Whether [link] is drawn right now: always while the link tool is armed
/// or the setting says always, otherwise only while one of its digits is
/// highlighted.
bool linkShown(PlayState state, NoteLink link, LinkVisibility visibility) =>
    state.linkArmed ||
    visibility == LinkVisibility.always ||
    state.highlights(link.digitA) ||
    state.highlights(link.digitB);
