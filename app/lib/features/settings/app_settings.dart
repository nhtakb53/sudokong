import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/theme/color_theme.dart';

/// How the digit keys under the board are arranged.
enum NumberPadLayout {
  /// 1-9 in a single row.
  oneRow,

  /// 1-5 on top, 6-9 below and offset by half a key, like a keyboard.
  twoRows;

  static NumberPadLayout fromName(String? name) => values.firstWhere(
    (v) => v.name == name,
    orElse: () => NumberPadLayout.twoRows,
  );
}

/// How a digit gets onto the board.
enum InputMode {
  /// Tap a cell, then a digit key.
  cellFirst,

  /// Pick a digit key (it stays active), then tap cells to place it.
  digitFirst;

  static InputMode fromName(String? name) => values.firstWhere(
    (v) => v.name == name,
    orElse: () => InputMode.cellFirst,
  );
}

/// Shape drawn behind a pencil mark that matches the highlighted digit.
enum NoteHighlightShape {
  roundedSquare,
  circle;

  static NoteHighlightShape fromName(String? name) => values.firstWhere(
    (v) => v.name == name,
    orElse: () => NoteHighlightShape.roundedSquare,
  );
}

/// When links drawn between pencil marks are shown.
enum LinkVisibility {
  /// Always.
  always,

  /// Only while one of the link's digits is highlighted (and while the
  /// link tool is armed).
  highlighted;

  static LinkVisibility fromName(String? name) => values.firstWhere(
    (v) => v.name == name,
    orElse: () => LinkVisibility.always,
  );
}

/// All user preferences in one immutable value.
///
/// Add a field, a default, a `copyWith` parameter and a JSON key; nothing
/// else needs to change. Unknown or broken keys fall back to defaults.
@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.colorTheme = ColorTheme.classic,
    this.numberPadLayout = NumberPadLayout.twoRows,
    this.noteHighlightShape = NoteHighlightShape.roundedSquare,
    this.inputMode = InputMode.cellFirst,
    this.longPressMs = defaultLongPressMs,
    this.linkVisibility = LinkVisibility.always,
    this.conjugatePairs = false,
    this.showTimer = true,
    this.autoHighlight = true,
  });

  static const int defaultLongPressMs = 400;
  static const int minLongPressMs = 200;
  static const int maxLongPressMs = 800;

  static const AppSettings defaults = AppSettings();
  static const int _version = 1;

  final ThemeMode themeMode;
  final ColorTheme colorTheme;
  final NumberPadLayout numberPadLayout;
  final NoteHighlightShape noteHighlightShape;
  final InputMode inputMode;

  /// How long a key or cell must be held to force a value entry.
  final int longPressMs;

  final LinkVisibility linkVisibility;

  /// Draw every conjugate pair of a highlighted digit as a thin line.
  final bool conjugatePairs;

  /// Show the clock on the play screen (it keeps running either way).
  final bool showTimer;

  /// Highlight the digit of a tapped cell or key. Long-press highlights
  /// work regardless.
  final bool autoHighlight;

  Duration get longPress => Duration(milliseconds: longPressMs);

  AppSettings copyWith({
    ThemeMode? themeMode,
    ColorTheme? colorTheme,
    NumberPadLayout? numberPadLayout,
    NoteHighlightShape? noteHighlightShape,
    InputMode? inputMode,
    int? longPressMs,
    LinkVisibility? linkVisibility,
    bool? conjugatePairs,
    bool? showTimer,
    bool? autoHighlight,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      colorTheme: colorTheme ?? this.colorTheme,
      numberPadLayout: numberPadLayout ?? this.numberPadLayout,
      noteHighlightShape: noteHighlightShape ?? this.noteHighlightShape,
      inputMode: inputMode ?? this.inputMode,
      longPressMs: (longPressMs ?? this.longPressMs).clamp(
        minLongPressMs,
        maxLongPressMs,
      ),
      linkVisibility: linkVisibility ?? this.linkVisibility,
      conjugatePairs: conjugatePairs ?? this.conjugatePairs,
      showTimer: showTimer ?? this.showTimer,
      autoHighlight: autoHighlight ?? this.autoHighlight,
    );
  }

  Map<String, Object?> toJson() => {
    'v': _version,
    'themeMode': themeMode.name,
    'colorTheme': colorTheme.name,
    'numberPadLayout': numberPadLayout.name,
    'noteHighlightShape': noteHighlightShape.name,
    'inputMode': inputMode.name,
    'longPressMs': longPressMs,
    'linkVisibility': linkVisibility.name,
    'conjugatePairs': conjugatePairs,
    'showTimer': showTimer,
    'autoHighlight': autoHighlight,
  };

  String toJsonString() => jsonEncode(toJson());

  static AppSettings fromJson(Map<String, Object?> json) {
    final mode = json['themeMode'];
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == mode,
        orElse: () => ThemeMode.system,
      ),
      colorTheme: ColorTheme.fromName(json['colorTheme'] as String?),
      numberPadLayout: NumberPadLayout.fromName(
        json['numberPadLayout'] as String?,
      ),
      noteHighlightShape: NoteHighlightShape.fromName(
        json['noteHighlightShape'] as String?,
      ),
      inputMode: InputMode.fromName(json['inputMode'] as String?),
      longPressMs: switch (json['longPressMs']) {
        final int ms => ms.clamp(minLongPressMs, maxLongPressMs),
        _ => defaultLongPressMs,
      },
      linkVisibility: LinkVisibility.fromName(
        json['linkVisibility'] as String?,
      ),
      conjugatePairs: json['conjugatePairs'] == true,
      showTimer: json['showTimer'] != false,
      autoHighlight: json['autoHighlight'] != false,
    );
  }

  /// Parses a stored string; returns [defaults] when it is missing or broken.
  static AppSettings fromJsonString(String? raw) {
    if (raw == null || raw.isEmpty) return defaults;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, Object?>) return fromJson(decoded);
      return defaults;
    } on FormatException {
      return defaults;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.themeMode == themeMode &&
      other.colorTheme == colorTheme &&
      other.numberPadLayout == numberPadLayout &&
      other.noteHighlightShape == noteHighlightShape &&
      other.inputMode == inputMode &&
      other.longPressMs == longPressMs &&
      other.linkVisibility == linkVisibility &&
      other.conjugatePairs == conjugatePairs &&
      other.showTimer == showTimer &&
      other.autoHighlight == autoHighlight;

  @override
  int get hashCode => Object.hash(
    themeMode,
    colorTheme,
    numberPadLayout,
    noteHighlightShape,
    inputMode,
    longPressMs,
    linkVisibility,
    conjugatePairs,
    showTimer,
    autoHighlight,
  );
}
