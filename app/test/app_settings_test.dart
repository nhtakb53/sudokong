import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudokong/core/theme/color_theme.dart';
import 'package:sudokong/features/settings/app_settings.dart';

void main() {
  test('defaults follow the system theme with the classic palette', () {
    expect(AppSettings.defaults.themeMode, ThemeMode.system);
    expect(AppSettings.defaults.colorTheme, ColorTheme.classic);
    expect(AppSettings.fromJsonString(null), AppSettings.defaults);
    expect(AppSettings.fromJsonString(''), AppSettings.defaults);
  });

  test('round-trips through JSON', () {
    const s = AppSettings(themeMode: ThemeMode.dark);
    expect(AppSettings.fromJsonString(s.toJsonString()), s);
    expect(s.toJson()['colorTheme'], 'classic');
    expect(s.toJson()['numberPadLayout'], 'twoRows');
    const one = AppSettings(numberPadLayout: NumberPadLayout.oneRow);
    expect(AppSettings.fromJsonString(one.toJsonString()), one);
    const circle = AppSettings(noteHighlightShape: NoteHighlightShape.circle);
    expect(AppSettings.fromJsonString(circle.toJsonString()), circle);
    expect(
      AppSettings.defaults.noteHighlightShape,
      NoteHighlightShape.roundedSquare,
    );
    const links = AppSettings(linkVisibility: LinkVisibility.highlighted);
    expect(AppSettings.fromJsonString(links.toJsonString()), links);
    expect(AppSettings.defaults.linkVisibility, LinkVisibility.always);
  });

  test('ignores unknown keys and bad values', () {
    expect(
      AppSettings.fromJsonString(
        '{"v":1,"themeMode":"purple","colorTheme":"neon","x":3}',
      ),
      AppSettings.defaults,
    );
    expect(AppSettings.fromJsonString('not json'), AppSettings.defaults);
    expect(AppSettings.fromJsonString('[1,2]'), AppSettings.defaults);
  });

  test('older payloads without colorTheme still load', () {
    final s = AppSettings.fromJsonString('{"v":1,"themeMode":"light"}');
    expect(s.themeMode, ThemeMode.light);
    expect(s.colorTheme, ColorTheme.classic);
    expect(s.numberPadLayout, NumberPadLayout.twoRows);
  });
}
