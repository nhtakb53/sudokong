import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/color_theme.dart';
import 'app_settings.dart';

/// Overridden in `main` with the real instance.
final sharedPreferencesProvider = Provider<SharedPreferencesWithCache>(
  (ref) =>
      throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

/// Loads settings synchronously from the preference cache and persists
/// every change.
class SettingsNotifier extends Notifier<AppSettings> {
  static const String storageKey = 'settings.v1';

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AppSettings.fromJsonString(prefs.getString(storageKey));
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _update(state.copyWith(themeMode: mode));

  Future<void> setColorTheme(ColorTheme theme) =>
      _update(state.copyWith(colorTheme: theme));

  Future<void> setNumberPadLayout(NumberPadLayout layout) =>
      _update(state.copyWith(numberPadLayout: layout));

  Future<void> setNoteHighlightShape(NoteHighlightShape shape) =>
      _update(state.copyWith(noteHighlightShape: shape));

  Future<void> setInputMode(InputMode mode) =>
      _update(state.copyWith(inputMode: mode));

  Future<void> setLongPressMs(int ms) =>
      _update(state.copyWith(longPressMs: ms));

  Future<void> setLinkVisibility(LinkVisibility visibility) =>
      _update(state.copyWith(linkVisibility: visibility));

  Future<void> setConjugatePairs(bool on) =>
      _update(state.copyWith(conjugatePairs: on));

  Future<void> setShowTimer(bool on) => _update(state.copyWith(showTimer: on));

  Future<void> setAutoHighlight(bool on) =>
      _update(state.copyWith(autoHighlight: on));

  Future<void> _update(AppSettings next) async {
    if (next == state) return;
    state = next;
    await ref
        .read(sharedPreferencesProvider)
        .setString(storageKey, next.toJsonString());
  }
}
