import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sudokong/features/settings/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPreferencesWithCache> freshCache() =>
      SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(),
      );

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('theme choice survives a restart', () async {
    final first = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(await freshCache()),
      ],
    );
    addTearDown(first.dispose);
    expect(first.read(settingsProvider).themeMode, ThemeMode.system);

    await first.read(settingsProvider.notifier).setThemeMode(ThemeMode.light);
    expect(first.read(settingsProvider).themeMode, ThemeMode.light);

    // A new cache and container stand in for a cold start.
    final second = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(await freshCache()),
      ],
    );
    addTearDown(second.dispose);
    expect(second.read(settingsProvider).themeMode, ThemeMode.light);
  });

  test('setting the same value again does not write', () async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(await freshCache()),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(settingsProvider.notifier);
    await notifier.setThemeMode(ThemeMode.dark);
    final before = container
        .read(sharedPreferencesProvider)
        .getString(SettingsNotifier.storageKey);
    await notifier.setThemeMode(ThemeMode.dark);
    final after = container
        .read(sharedPreferencesProvider)
        .getString(SettingsNotifier.storageKey);
    expect(after, before);
    expect(container.read(settingsProvider).themeMode, ThemeMode.dark);
  });
}
