import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/play/game_timer.dart';
import 'features/play/play_controller.dart';
import 'features/settings/settings_provider.dart';

class SudokongApp extends ConsumerStatefulWidget {
  const SudokongApp({super.key});

  @override
  ConsumerState<SudokongApp> createState() => _SudokongAppState();
}

class _SudokongAppState extends ConsumerState<SudokongApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Leaving the app pauses the clock and saves the game; the player
    // resumes the clock by hand. Coming back re-asserts the system bars'
    // state, which Android may have reset meanwhile.
    _lifecycle = AppLifecycleListener(
      onHide: _park,
      onPause: _park,
      onResume: _applySystemBars,
    );
    _applySystemBars();
  }

  /// Fullscreen hides the status and navigation bars; a swipe from an
  /// edge peeks them briefly.
  void _applySystemBars() {
    final fullscreen = ref.read(settingsProvider).fullscreen;
    SystemChrome.setEnabledSystemUIMode(
      fullscreen ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  void _park() {
    ref.read(gameTimerProvider.notifier).pause();
    ref.read(playControllerProvider.notifier).saveNow();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    ref.listen(
      settingsProvider.select((s) => s.fullscreen),
      (_, _) => _applySystemBars(),
    );
    return MaterialApp(
      title: 'Sudokong',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(settings.colorTheme),
      darkTheme: AppTheme.dark(settings.colorTheme),
      themeMode: settings.themeMode,
      home: const HomeScreen(),
    );
  }
}
