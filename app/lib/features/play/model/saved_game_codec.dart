import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:sudoku_engine/sudoku_engine.dart';

import 'play_state.dart';

/// A game as it was last saved: the board plus the clock.
@immutable
class SavedGame {
  const SavedGame(this.state, this.seconds);
  final PlayState state;
  final int seconds;
}

/// JSON form of a game for restoring after the app restarts. Undo history,
/// selection, highlights and armed tools are not kept.
abstract final class SavedGameCodec {
  static const int version = 1;

  static Map<String, Object?> encode(PlayState s, int seconds) => {
    'v': version,
    'puzzle': GridCodec.format(s.givens),
    'solution': GridCodec.format(s.solution),
    'values': GridCodec.format(s.values),
    'notes': List<int>.of(s.notes),
    'cellColors': _digits(s.cellColors),
    'noteColors': _digits(s.noteColors),
    'links': [
      for (final l in s.links)
        [
          l.cellA,
          l.digitA,
          l.cellB,
          l.digitB,
          l.strong ? 1 : 0,
          l.manual ? 1 : 0,
        ],
    ],
    'seed': s.seed,
    'seconds': seconds,
    'completed': s.completed,
  };

  static String encodeString(PlayState s, int seconds) =>
      jsonEncode(encode(s, seconds));

  /// The saved game, or null when [raw] is missing, broken or from a
  /// version this build cannot read.
  static SavedGame? decodeString(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) return null;
      return decode(decoded);
    } on FormatException {
      return null;
    }
  }

  static SavedGame? decode(Map<String, Object?> json) {
    try {
      if (json['v'] != version) return null;
      // Boards are read leniently: a saved board may hold conflicts, which
      // the strict engine parser would reject.
      final givens = _cells(json['puzzle'] as String);
      final solution = _cells(json['solution'] as String);
      final values = _cells(json['values'] as String);
      final notes = Uint16List.fromList(
        (json['notes'] as List).cast<int>().map((n) => n & 0x1FF).toList(),
      );
      if (notes.length != 81) return null;
      final cellColors = _fromDigits(json['cellColors'] as String?, 81);
      final noteColors = _fromDigits(json['noteColors'] as String?, 81 * 9);
      final links = <NoteLink>[];
      for (final raw in (json['links'] as List? ?? const [])) {
        final l = (raw as List).cast<int>();
        if (l.length < 5) continue;
        final ok =
            [l[0], l[2]].every((c) => c >= 0 && c <= 80) &&
            [l[1], l[3]].every((d) => d >= 1 && d <= 9);
        if (!ok) continue;
        links.add(
          NoteLink(
            cellA: l[0],
            digitA: l[1],
            cellB: l[2],
            digitB: l[3],
            strong: l[4] != 0,
            manual: l.length > 5 && l[5] != 0,
          ),
        );
      }
      final state = PlayState(
        givens: givens,
        solution: solution,
        values: values,
        notes: notes,
        seed: json['seed'] as int? ?? 0,
        cellColors: cellColors,
        noteColors: noteColors,
        links: List.unmodifiable(links),
        completed: json['completed'] == true,
      );
      final seconds = json['seconds'] as int? ?? 0;
      return SavedGame(state, seconds < 0 ? 0 : seconds);
    } on Object {
      return null;
    }
  }

  /// 81 cells from one character each: digits stay, anything else is 0.
  static Uint8List _cells(String text) {
    if (text.length != 81) throw const FormatException('board length');
    final out = Uint8List(81);
    for (var i = 0; i < 81; i++) {
      final v = text.codeUnitAt(i) - 48;
      out[i] = v >= 1 && v <= 9 ? v : 0;
    }
    return out;
  }

  /// Small ints (0-9) packed one character each.
  static String _digits(Uint8List bytes) =>
      String.fromCharCodes(bytes.map((b) => 48 + b.clamp(0, 9)));

  static Uint8List _fromDigits(String? text, int length) {
    final out = Uint8List(length);
    if (text == null) return out;
    for (var i = 0; i < length && i < text.length; i++) {
      final v = text.codeUnitAt(i) - 48;
      out[i] = v < 0 || v > 9 ? 0 : v;
    }
    return out;
  }
}
