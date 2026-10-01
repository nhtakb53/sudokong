import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/app_sheet.dart';
import '../help/glossary_screen.dart';
import '../settings/settings_screen.dart';
import 'model/play_intent.dart';
import 'model/play_state.dart';
import 'game_timer.dart';
import 'play_controller.dart';
import 'widgets/board_view.dart';
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

  /// Which marks and links to drop, one layer or all of them.
  void _showWipeSheet(BuildContext context, PlayState state) {
    final controller = ref.read(playControllerProvider.notifier);
    final cells = state.cellColors.where((c) => c != 0).length;
    final marks = state.noteColors.where((c) => c != 0).length;
    void wipe(PlayIntent intent) {
      HapticFeedback.mediumImpact();
      controller.dispatch(intent);
    }

    showAppSheet(
      context,
      title: '지우기',
      items: [
        AppSheetItem(
          icon: Icons.polyline_outlined,
          label: '연결만 지우기',
          detail: '연결 ${state.links.length}개',
          enabled: state.links.isNotEmpty,
          onTap: () => wipe(const ClearLinks()),
        ),
        AppSheetItem(
          icon: Icons.crop_square_rounded,
          label: '칸 색칠만 지우기',
          detail: '칸 $cells개',
          enabled: cells > 0,
          onTap: () => wipe(const ClearCellPaint()),
        ),
        AppSheetItem(
          icon: Icons.apps_rounded,
          label: '후보 색칠만 지우기',
          detail: '후보수 $marks개',
          enabled: marks > 0,
          onTap: () => wipe(const ClearNotePaint()),
        ),
        AppSheetItem(
          icon: Icons.layers_clear_outlined,
          label: '모두 지우기',
          detail: '연결과 색칠 전부',
          destructive: true,
          onTap: () => wipe(const ClearPaint()),
        ),
      ],
    );
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
              timeLabel: ref.read(gameTimerProvider).label,
              onNewGame: () =>
                  ref.read(playControllerProvider.notifier).newGame(),
            ),
          );
        }
      },
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
                    child: Column(
                      children: [
                        SizedBox(
                          height: 48,
                          child: Row(
                            children: [
                              IconButton(
                                tooltip: '홈으로',
                                icon: const Icon(Icons.arrow_back_rounded),
                                onPressed: () =>
                                    Navigator.of(context).maybePop(),
                              ),
                              const TimerChip(),
                              const Spacer(),
                              // Fills every mark from the rules, also to
                              // repair marks after a slip.
                              IconButton(
                                tooltip: '후보 채움',
                                icon: const Icon(Icons.edit_note_rounded),
                                onPressed: locked
                                    ? null
                                    : () {
                                        HapticFeedback.lightImpact();
                                        ref
                                            .read(
                                              playControllerProvider.notifier,
                                            )
                                            .dispatch(const FillCandidates());
                                      },
                              ),
                              // One button, four wipes: links, cell paint, mark paint,
                              // or everything. Undo brings any of them back.
                              IconButton(
                                tooltip: '지우기 메뉴',
                                icon: const Icon(Icons.layers_clear_outlined),
                                onPressed:
                                    locked ||
                                        !(state.hasPaint ||
                                            state.links.isNotEmpty)
                                    ? null
                                    : () => _showWipeSheet(context, state),
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
                              IconButton(
                                tooltip: '용어 설명',
                                icon: const Icon(Icons.help_outline_rounded),
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const GlossaryScreen(),
                                  ),
                                ),
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
                        const SizedBox(height: 12),
                        IgnorePointer(
                          ignoring: locked,
                          child: Opacity(
                            opacity: locked ? 0.4 : 1,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
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
      ),
    );
  }
}
