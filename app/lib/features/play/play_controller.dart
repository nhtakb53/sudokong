import 'dart:async';
import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sudoku_engine/sudoku_engine.dart';

import '../settings/settings_provider.dart';
import 'game_store.dart';
import 'game_timer.dart';
import 'model/play_intent.dart';
import 'model/play_reducer.dart';
import 'model/play_state.dart';

final playControllerProvider = AsyncNotifierProvider<PlayController, PlayState>(
  PlayController.new,
);

/// Owns the current game: restores the saved one on start, generates new
/// ones off the UI isolate, and keeps the game in progress saved.
class PlayController extends AsyncNotifier<PlayState> {
  Timer? _pendingSave;

  static const Duration saveDelay = Duration(milliseconds: 300);

  @override
  Future<PlayState> build() async {
    ref.onDispose(() => _pendingSave?.cancel());
    final saved = ref.read(gameStoreProvider).load();
    if (saved != null) {
      final seconds = saved.seconds;
      // Another provider cannot be changed while this one builds.
      Future<void>(() => ref.read(gameTimerProvider.notifier).restore(seconds));
      return saved.state;
    }
    return _generate();
  }

  Future<PlayState> _generate() async {
    final puzzle = await Isolate.run(() => SudokuEngine.generate());
    return PlayState.fromPuzzle(puzzle);
  }

  /// Starts a fresh puzzle, restarts the clock and saves it.
  Future<void> newGame() async {
    _pendingSave?.cancel();
    state = const AsyncLoading();
    state = await AsyncValue.guard(_generate);
    final timer = ref.read(gameTimerProvider.notifier);
    timer.reset();
    timer.resume();
    await saveNow();
  }

  /// Applies [intent] through the pure reducer. Board changes are saved a
  /// moment later; a solved board ends the clock and drops the save.
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
      _pendingSave?.cancel();
      ref.read(gameTimerProvider.notifier).stop();
      unawaited(ref.read(gameStoreProvider).clear());
      return;
    }
    final boardChanged =
        !identical(next.values, current.values) ||
        !identical(next.notes, current.notes) ||
        !identical(next.cellColors, current.cellColors) ||
        !identical(next.noteColors, current.noteColors) ||
        !identical(next.links, current.links);
    if (boardChanged) scheduleSave();
  }

  /// Saves a moment after the last board change, so a burst of edits is
  /// written once.
  void scheduleSave() {
    _pendingSave?.cancel();
    _pendingSave = Timer(saveDelay, saveNow);
  }

  /// Writes the game and its clock now (leaving the screen, backgrounding).
  Future<void> saveNow() async {
    _pendingSave?.cancel();
    final current = state.value;
    if (current == null || current.completed) return;
    await ref
        .read(gameStoreProvider)
        .save(current, ref.read(gameTimerProvider).seconds);
  }
}
