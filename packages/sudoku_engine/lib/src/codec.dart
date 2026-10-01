import 'dart:typed_data';

import 'grid.dart';

/// Why a puzzle string was rejected.
enum CodecError {
  /// The string is not exactly 81 characters.
  length,

  /// A character other than `.`, `0`-`9` was found.
  character,

  /// Two equal digits share a row, column or box.
  conflict,
}

/// Thrown by [GridCodec.parse] for malformed input.
final class CodecException implements Exception {
  const CodecException(this.error, [this.index = -1]);

  final CodecError error;

  /// Offending character index, or -1 when not applicable.
  final int index;

  @override
  String toString() => 'CodecException(${error.name}, index: $index)';
}

/// Converts between the 81-character puzzle format and cell arrays.
///
/// Empty cells are written as `.` and read as `.` or `0`.
abstract final class GridCodec {
  static const int _dot = 0x2E;
  static const int _zero = 0x30;
  static const int _nine = 0x39;

  /// Parses [source] into 81 values (0 = empty).
  ///
  /// Throws [CodecException] on bad length, bad characters or rule conflicts.
  static Uint8List parse(String source) {
    if (source.length != 81) throw const CodecException(CodecError.length);
    final cells = Uint8List(81);
    for (var i = 0; i < 81; i++) {
      final ch = source.codeUnitAt(i);
      if (ch == _dot || ch == _zero) continue;
      if (ch < _zero || ch > _nine) throw CodecException(CodecError.character, i);
      cells[i] = ch - _zero;
    }
    if (Grid.tryFrom(cells) == null) {
      throw const CodecException(CodecError.conflict);
    }
    return cells;
  }

  /// Formats [cells] as 81 characters, using [empty] for blank cells.
  static String format(Uint8List cells, {String empty = '.'}) {
    final buffer = StringBuffer();
    for (var i = 0; i < 81; i++) {
      final d = cells[i];
      buffer.write(d == 0 ? empty : d);
    }
    return buffer.toString();
  }

  /// Returns the first problem with [source], or `null` when it is valid.
  static CodecError? validate(String source) {
    try {
      parse(source);
      return null;
    } on CodecException catch (e) {
      return e.error;
    }
  }
}
