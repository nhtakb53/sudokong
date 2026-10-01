import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sudokong/features/play/game_store.dart';
import 'package:sudokong/features/play/game_timer.dart';
import 'package:sudokong/features/play/model/play_intent.dart';
import 'package:sudokong/features/play/model/play_reducer.dart';
import 'package:sudokong/features/play/model/play_state.dart';
import 'package:sudokong/features/play/model/saved_game_codec.dart';
import 'package:sudokong/features/play/play_controller.dart';
import 'package:sudokong/features/settings/settings_provider.dart';
import 'package:sudoku_engine/sudoku_engine.dart';

const _puzzle =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

/// A clock that never ticks, so tests end with no pending timers.
class _StillTimer extends GameTimer {
  @override
  GameTimerState build() => const GameTimerState(paused: true);
}

void main() {
  late SharedPreferencesWithCache prefs;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
  });

  ProviderContainer make() {
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        gameTimerProvider.overrideWith(_StillTimer.new),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('a saved game is restored with its clock', () async {
    var s = PlayState.fromPuzzle(
      const GeneratedPuzzle(
        puzzle: _puzzle,
        solution: _solution,
        givens: 30,
        seed: 7,
      ),
    );
    s = reduce(s, const SelectCell(2));
    s = reduce(s, const EnterDigit(4));
    await prefs.setString(GameStore.key, SavedGameCodec.encodeString(s, 321));

    final c = make();
    final restored = await c.read(playControllerProvider.future);
    expect(restored.values[2], 4);
    expect(restored.seed, 7);
    await Future<void>.delayed(Duration.zero); // the clock restore is queued
    expect(c.read(gameTimerProvider).seconds, 321);
    expect(c.read(gameTimerProvider).paused, isTrue);
  });

  test('board changes are saved; a solved board drops the save', () async {
    final c = make();
    await c.read(playControllerProvider.future);
    expect(prefs.getString(GameStore.key), isNull, reason: 'nothing yet');
    final controller = c.read(playControllerProvider.notifier);
    final state = c.read(playControllerProvider).value!;
    final empty = state.values.indexWhere((v) => v == 0);
    controller.dispatch(SelectCell(empty));
    controller.dispatch(const EnterDigit(1));
    await controller.saveNow();
    final saved = SavedGameCodec.decodeString(prefs.getString(GameStore.key));
    expect(saved, isNotNull);
    expect(saved!.state.values[empty], 1);

    // Solve it: fill every cell from the solution.
    for (var i = 0; i < 81; i++) {
      if (state.givens[i] != 0) continue;
      final latest = c.read(playControllerProvider).value!;
      if (latest.values[i] == latest.solution[i]) continue;
      controller.dispatch(SelectCell(i));
      if (latest.values[i] != 0) controller.dispatch(const Erase());
      controller.dispatch(EnterDigit(state.solution[i]));
    }
    expect(c.read(playControllerProvider).value!.completed, isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(prefs.getString(GameStore.key), isNull, reason: 'cleared');
  });
}
