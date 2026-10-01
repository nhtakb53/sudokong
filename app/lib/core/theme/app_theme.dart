import 'package:flutter/material.dart';

import 'board_colors.dart';
import 'color_theme.dart';

abstract final class AppTheme {
  static const String fontFamily = 'Pretendard';

  static ThemeData light(ColorTheme theme) => build(theme, Brightness.light);

  static ThemeData dark(ColorTheme theme) => build(theme, Brightness.dark);

  static ThemeData build(ColorTheme theme, Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final scaffold = theme.scaffold(brightness);
    final seeded = ColorScheme.fromSeed(
      seedColor: theme.seed,
      brightness: brightness,
    );
    // Surface tiers drive grouped settings cards and sheets. They stay in the
    // same neutral family as the board so every screen reads as one app.
    final scheme = isLight
        ? seeded.copyWith(
            surface: scaffold,
            // Off-white cards on a calmer ground: no pure white anywhere.
            surfaceContainerLowest: const Color(0xFFF8F9FB),
            surfaceContainerLow: const Color(0xFFF8F9FB),
            surfaceContainer: const Color(0xFFF8F9FB),
            surfaceContainerHigh: const Color(0xFFE6EBF2),
            surfaceContainerHighest: const Color(0xFFDFE6EF),
            outlineVariant: const Color(0xFFD6DEE8),
          )
        : seeded.copyWith(
            surface: scaffold,
            surfaceContainerLowest: const Color(0xFF0F1012),
            surfaceContainerLow: const Color(0xFF1A1B1E),
            surfaceContainer: const Color(0xFF1F2124),
            surfaceContainerHigh: const Color(0xFF292B30),
            surfaceContainerHighest: const Color(0xFF33363C),
            outlineVariant: const Color(0xFF363940),
          );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: scaffold,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        surfaceTintColor: Colors.transparent,
      ),
      extensions: [theme.board(brightness)],
    );
  }
}

extension BoardColorsContext on BuildContext {
  BoardColors get boardColors => Theme.of(this).extension<BoardColors>()!;
}
