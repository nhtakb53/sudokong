import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../help/glossary_screen.dart';
import '../settings/settings_provider.dart';
import '../settings/settings_screen.dart';
import 'model/play_intent.dart';
import 'game_timer.dart';
import 'play_controller.dart';
import 'widgets/board_view.dart';
import 'widgets/console_metrics.dart';
import 'widgets/completion_dialog.dart';
import 'widgets/number_pad.dart';
import 'widgets/pause_overlay.dart';
import 'widgets/play_toolbar.dart';
import 'widgets/timer_chip.dart';

/// The board, the digit keys and a settings entry. Nothing else yet.
class PlayScreen extends ConsumerStatefulWidget {
  const PlayScreen({super.key});

  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends ConsumerState<PlayScreen> {
  @override
  void initState() {
    super.initState();
    // The clock runs only while this screen is on show.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(gameTimerProvider.notifier).resume();
    });
  }

  /// Leaving for the home screen: stop the clock and keep the game.
  void _park() {
    ref.read(gameTimerProvider.notifier).pause();
    ref.read(playControllerProvider.notifier).saveNow();
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(playControllerProvider);
    // A finished clock is paused too, but the solved board stays on show.
    final paused = ref.watch(
      gameTimerProvider.select((t) => t.paused && !t.finished),
    );
    final completed = game.value?.completed ?? false;
    final locked = paused || completed;

    ref.listen<bool>(
      playControllerProvider.select((g) => g.value?.completed ?? false),
      (was, now) {
        if (now && was != true) {
          showDialog<void>(
            context: context,
            builder: (_) => CompletionDialog(
              timeLabel: ref.read(settingsProvider).showTimer
                  ? ref.read(gameTimerProvider).label
                  : null,
              onNewGame: () =>
                  ref.read(playControllerProvider.notifier).newGame(),
            ),
          );
        }
      },
    );

    final padLayout = ref.watch(
      settingsProvider.select((s) => s.numberPadLayout),
    );
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _park();
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Bottom layer: only taps that no cell, key or button claims fall
            // through to it, so it never competes with the board's own taps.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => ref
                    .read(playControllerProvider.notifier)
                    .dispatch(const ClearSelection()),
              ),
            ),
            SafeArea(
              child: game.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('$error')),
                data: (state) => Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // The board keeps its full width; the console
                        // below it shrinks to fit what is left.
                        final metrics = ConsoleMetrics.fit(
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          layout: padLayout,
                        );
                        final scale = metrics.scale;
                        return Column(
                          children: [
                            // Six icon buttons share the row with the clock, so they sit
                            // at the compact density.
                            SizedBox(
                              height: 48,
                              child: IconButtonTheme(
                                data: IconButtonThemeData(
                                  style: IconButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      tooltip: '홈으로',
                                      icon: const Icon(
                                        Icons.arrow_back_rounded,
                                      ),
                                      onPressed: () =>
                                          Navigator.of(context).maybePop(),
                                    ),
                                    if (ref.watch(
                                      settingsProvider.select(
                                        (s) => s.showTimer,
                                      ),
                                    ))
                                      const TimerChip(),
                                    const Spacer(),
                                    IconButton(
                                      tooltip: '설정',
                                      icon: const Icon(Icons.settings_outlined),
                                      onPressed: () => Navigator.of(context)
                                          .push(
                                            MaterialPageRoute<void>(
                                              builder: (_) =>
                                                  const SettingsScreen(),
                                            ),
                                          ),
                                    ),
                                    IconButton(
                                      tooltip: '용어 설명',
                                      icon: const Icon(
                                        Icons.help_outline_rounded,
                                      ),
                                      onPressed: () => Navigator.of(context)
                                          .push(
                                            MaterialPageRoute<void>(
                                              builder: (_) =>
                                                  const GlossaryScreen(),
                                            ),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // The board takes whatever height is left above the
                            // console, so it never overflows on a short screen;
                            // on a tall one it stays width-bound and sits right
                            // above the toolbar, with the slack above it.
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  child: paused
                                      ? PauseOverlay(
                                          onResume: () => ref
                                              .read(gameTimerProvider.notifier)
                                              .resume(),
                                        )
                                      : BoardView(state: state),
                                ),
                              ),
                            ),
                            SizedBox(height: ConsoleMetrics.boardGap * scale),
                            IgnorePointer(
                              ignoring: locked,
                              child: Opacity(
                                opacity: locked ? 0.4 : 1,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  child: PlayToolbar(
                                    state: state,
                                    scale: scale,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: ConsoleMetrics.toolbarGap * scale),
                            IgnorePointer(
                              ignoring: locked,
                              child: Opacity(
                                opacity: locked ? 0.4 : 1,
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    6,
                                    0,
                                    6,
                                    ConsoleMetrics.bottomPad * scale,
                                  ),
                                  child: NumberPad(
                                    values: state.values,
                                    highlightSlots: state.highlightSlots,
                                    activeDigit: state.activeDigit,
                                    noteMode: state.noteMode,
                                    selectedWritable:
                                        state.selected != null &&
                                        !state.isGiven(state.selected!),
                                    paintColor: state.paintArmed
                                        ? state.paintColor
                                        : -1,
                                    layout: metrics.layout,
                                    scale: scale,
                                    reserveOneRow: metrics.reserveOneRow,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
