import 'package:flutter/material.dart';

import 'board_colors.dart';

/// A named color palette. Each value carries everything a theme needs for
/// both brightnesses, so adding a palette later means adding one value here
/// and nothing else.
enum ColorTheme {
  classic(
    seed: Color(0xFF325AAF),
    lightScaffold: Color(0xFFEDF1F6),
    darkScaffold: Color(0xFF141518),
    lightBoard: BoardColors.light,
    darkBoard: BoardColors.dark,
  );

  const ColorTheme({
    required this.seed,
    required this.lightScaffold,
    required this.darkScaffold,
    required this.lightBoard,
    required this.darkBoard,
  });

  /// Seed for the Material color scheme (buttons, switches, selection).
  final Color seed;
  final Color lightScaffold;
  final Color darkScaffold;
  final BoardColors lightBoard;
  final BoardColors darkBoard;

  Color scaffold(Brightness b) =>
      b == Brightness.light ? lightScaffold : darkScaffold;

  BoardColors board(Brightness b) =>
      b == Brightness.light ? lightBoard : darkBoard;

  static ColorTheme fromName(String? name) => values.firstWhere(
    (v) => v.name == name,
    orElse: () => ColorTheme.classic,
  );
}
