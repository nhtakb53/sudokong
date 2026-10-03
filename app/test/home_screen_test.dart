import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sudokong/core/theme/app_theme.dart';
import 'package:sudokong/core/theme/color_theme.dart';
import 'package:sudokong/features/home/home_screen.dart';
import 'package:sudokong/features/play/game_timer.dart';
import 'package:sudokong/features/play/model/play_intent.dart';
import 'package:sudokong/features/play/model/play_reducer.dart';
import 'package:sudokong/features/play/model/play_state.dart';
import 'package:sudokong/features/play/play_controller.dart';
import 'package:sudokong/features/play/play_screen.dart';
import 'package:sudokong/features/settings/settings_provider.dart';
import 'package:sudoku_engine/sudoku_engine.dart';

const _puzzle =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

PlayState _fresh() => PlayState.fromPuzzle(
  const GeneratedPuzzle(
    puzzle: _puzzle,
    solution: _solution,
    givens: 30,
    seed: 1,
  ),
);

class _FreshController extends PlayController {
  @override
  void scheduleSave() {}

  @override
  Future<PlayState> build() async => _fresh();
}

class _PlayedController extends PlayController {
  @override
  void scheduleSave() {}

  @override
  Future<PlayState> build() async {
    final s = reduce(_fresh(), const SelectCell(2));
    return reduce(s, const EnterDigit(4));
  }
}

class _StillTimer extends GameTimer {
  @override
  GameTimerState build() => const GameTimerState(seconds: 75, paused: true);
}

void main() {
  Future<void> pumpHome(WidgetTester tester, {required bool played}) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          gameTimerProvider.overrideWith(_StillTimer.new),
          playControllerProvider.overrideWith(
            played ? _PlayedController.new : _FreshController.new,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.build(ColorTheme.classic, Brightness.light),
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('an untouched game offers only a new game', (tester) async {
    await pumpHome(tester, played: false);
    final resume = tester.widget<FilledButton>(
      find.byKey(const ValueKey('home-resume')),
    );
    expect(resume.onPressed, isNull);
    expect(find.textContaining('진행 중인 게임'), findsNothing);
  });

  testWidgets('a played game can be resumed and left again', (tester) async {
    await pumpHome(tester, played: true);
    await tester.tap(find.byKey(const ValueKey('home-resume')));
    await tester.pumpAndSettle();
    expect(find.byType(PlayScreen), findsOneWidget);
    await tester.tap(find.byTooltip('홈으로'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(PlayScreen), findsNothing);
  });
}
