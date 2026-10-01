import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sudoku_engine/sudoku_engine.dart';

import '../settings/settings_provider.dart';
import 'game_timer.dart';
import 'model/play_intent.dart';
import 'model/play_reducer.dart';
import 'model/play_state.dart';

final playControllerProvider = AsyncNotifierProvider<PlayController, PlayState>(
  PlayController.new,
);

/// Owns the current game. Generation runs off the UI isolate.
class PlayController extends AsyncNotifier<PlayState> {
  @override
  Future<PlayState> build() => _generate();

  Future<PlayState> _generate() async {
    final puzzle = await Isolate.run(() => SudokuEngine.generate());
    return PlayState.fromPuzzle(puzzle);
  }

  /// Starts a fresh puzzle and restarts the clock.
  Future<void> newGame() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_generate);
    final timer = ref.read(gameTimerProvider.notifier);
    timer.reset();
    timer.resume();
  }

  /// Applies [intent] through the pure reducer.
  void dispatch(PlayIntent intent) {
    final current = state.value;
    if (current == null) return;
    final next = reduce(
      current,
      intent,
      inputMode: ref.read(settingsProvider).inputMode,
    );
    if (identical(next, current)) return;
    state = AsyncData(next);
    if (next.completed && !current.completed) {
      ref.read(gameTimerProvider.notifier).stop();
    }
  }
}
