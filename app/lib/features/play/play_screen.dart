import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../help/glossary_screen.dart';
import '../settings/settings_screen.dart';
import 'model/play_intent.dart';
import 'game_timer.dart';
import 'play_controller.dart';
import 'widgets/board_view.dart';
import 'widgets/completion_dialog.dart';
import 'widgets/number_pad.dart';
import 'widgets/pause_overlay.dart';
import 'widgets/play_toolbar.dart';
import 'widgets/timer_chip.dart';

enum _MoreItem { glossary }

/// The board, the digit keys and a settings entry. Nothing else yet.
class PlayScreen extends ConsumerWidget {
  const PlayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              timeLabel: ref.read(gameTimerProvider).label,
              onNewGame: () =>
                  ref.read(playControllerProvider.notifier).newGame(),
            ),
          );
        }
      },
    );

    Future<void> confirmNewGame() async {
      if (completed) {
        await ref.read(playControllerProvider.notifier).newGame();
        return;
      }
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('새 게임을 시작할까요?'),
          content: const Text('지금 퍼즐은 사라집니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('새 게임'),
            ),
          ],
        ),
      );
      if (ok == true) {
        await ref.read(playControllerProvider.notifier).newGame();
      }
    }

    return Scaffold(
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
                  child: Column(
                    children: [
                      SizedBox(
                        height: 48,
                        child: Row(
                          children: [
                            const SizedBox(width: 6),
                            const TimerChip(),
                            const Spacer(),
                            IconButton(
                              tooltip: '새 게임',
                              icon: const Icon(
                                Icons.add_circle_outline_rounded,
                              ),
                              onPressed: confirmNewGame,
                            ),
                            IconButton(
                              tooltip: '설정',
                              icon: const Icon(Icons.settings_outlined),
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const SettingsScreen(),
                                ),
                              ),
                            ),
                            PopupMenuButton<_MoreItem>(
                              tooltip: '도움말',
                              icon: const Icon(Icons.help_outline_rounded),
                              onSelected: (item) => switch (item) {
                                _MoreItem.glossary =>
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const GlossaryScreen(),
                                    ),
                                  ),
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: _MoreItem.glossary,
                                  child: ListTile(
                                    leading: Icon(Icons.menu_book_outlined),
                                    title: Text('용어 설명'),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
                            padding: const EdgeInsets.symmetric(horizontal: 6),
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
                      const SizedBox(height: 12),
                      IgnorePointer(
                        ignoring: locked,
                        child: Opacity(
                          opacity: locked ? 0.4 : 1,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: PlayToolbar(state: state),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      IgnorePointer(
                        ignoring: locked,
                        child: Opacity(
                          opacity: locked ? 0.4 : 1,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(6, 0, 6, 12),
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
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
