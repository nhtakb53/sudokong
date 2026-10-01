import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sudokong/core/theme/app_theme.dart';
import 'package:sudokong/core/theme/color_theme.dart';
import 'package:sudokong/features/play/model/play_state.dart';
import 'package:sudokong/features/play/game_timer.dart';
import 'package:sudokong/features/play/play_controller.dart';
import 'package:sudokong/features/play/play_screen.dart';
import 'package:sudokong/features/play/widgets/board_view.dart';
import 'package:sudokong/features/play/widgets/number_pad.dart';
import 'package:sudokong/features/play/widgets/play_toolbar.dart';
import 'package:sudokong/features/settings/settings_provider.dart';
import 'package:sudoku_engine/sudoku_engine.dart';

const _puzzle =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

class _FixedPlayController extends PlayController {
  @override
  void scheduleSave() {}

  @override
  Future<PlayState> build() async => PlayState.fromPuzzle(
    const GeneratedPuzzle(
      puzzle: _puzzle,
      solution: _solution,
      givens: 30,
      seed: 1,
    ),
  );
}

/// A clock that never ticks, so tests end with no pending timers.
class _StillTimer extends GameTimer {
  @override
  GameTimerState build() => const GameTimerState();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  Future<void> pumpPlay(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        gameTimerProvider.overrideWith(_StillTimer.new),
        playControllerProvider.overrideWith(_FixedPlayController.new),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.build(ColorTheme.classic, Brightness.light),
          home: const PlayScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  PlayState state() => container.read(playControllerProvider).value!;

  /// Center of cell (row, col) on the rendered board.
  Offset cellCenter(WidgetTester tester, int row, int col) {
    final rect = tester.getRect(find.byType(BoardView));
    return Offset(
      rect.left + rect.width / 9 * (col + 0.5),
      rect.top + rect.height / 9 * (row + 0.5),
    );
  }

  testWidgets('the screen fits with status-bar and navigation insets', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    tester.view.padding = const FakeViewPadding(top: 88, bottom: 64);
    addTearDown(tester.view.reset);
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        gameTimerProvider.overrideWith(_StillTimer.new),
        playControllerProvider.overrideWith(_FixedPlayController.new),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.build(ColorTheme.classic, Brightness.light),
          home: const PlayScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'no overflow');
    final board = tester.getRect(find.byType(BoardView));
    final pad = tester.getRect(find.byType(NumberPad));
    expect(board.bottom, lessThan(pad.top));
    expect(
      pad.bottom,
      lessThanOrEqualTo(tester.getRect(find.byType(PlayScreen)).bottom),
    );
  });

  testWidgets('tap a cell, then a key: the digit lands in that cell', (
    tester,
  ) async {
    await pumpPlay(tester);
    await tester.tapAt(cellCenter(tester, 0, 2)); // r1c3, empty
    await tester.pump();
    expect(state().selected, 2);

    await tester.tap(find.byKey(const ValueKey('numpad-4')));
    await tester.pump();
    expect(state().values[2], 4);
    expect(state().highlightOrder, [4]);
  });

  testWidgets('a key press highlights its digit without a selection', (
    tester,
  ) async {
    await pumpPlay(tester);
    await tester.tap(find.byKey(const ValueKey('numpad-7')));
    await tester.pump();
    expect(state().selected, isNull);
    expect(state().highlightOrder, [7]);
  });

  testWidgets('held keys build a multi-digit highlight, or write', (
    tester,
  ) async {
    await pumpPlay(tester);
    await tester.longPress(find.byKey(const ValueKey('numpad-3')));
    await tester.pump();
    expect(state().highlightOrder, [3]);
    await tester.longPress(find.byKey(const ValueKey('numpad-7')));
    await tester.pump();
    expect(state().highlightOrder, [3, 7]);

    // A cell tap keeps the set; the tapped digit becomes the active one.
    await tester.tapAt(cellCenter(tester, 0, 0)); // given 5
    await tester.pump();
    expect(state().highlightOrder, [3, 7]);
    expect(state().activeDigit, 5);

    // With a writable cell selected the hold writes instead.
    await tester.tapAt(cellCenter(tester, 0, 2)); // empty
    await tester.pump();
    await tester.longPress(find.byKey(const ValueKey('numpad-4')));
    await tester.pump();
    expect(state().values[2], 4);
    expect(state().highlightOrder, [3, 7], reason: 'the set survives a write');

    // Empty space clears everything.
    final toolbar = tester.getRect(find.byType(PlayToolbar));
    final pad = tester.getRect(find.byType(NumberPad));
    await tester.tapAt(
      Offset(toolbar.center.dx, (toolbar.bottom + pad.top) / 2),
    );
    await tester.pump();
    expect(state().highlightOrder, isEmpty);
  });

  testWidgets('the link tool draws a chain between tapped marks', (
    tester,
  ) async {
    await pumpPlay(tester);
    await tester.tap(find.byTooltip('후보 채움'));
    await tester.pump();
    await tester.tap(find.text('연결'));
    await tester.pump();
    expect(state().linkArmed, isTrue);
    // Mark 4 sits in the middle-left slot of its cell.
    final board = tester.getRect(find.byType(BoardView));
    Offset mark4(int row, int col) =>
        cellCenter(tester, row, col) + Offset(-board.width / 27, 0);
    await tester.tapAt(mark4(0, 2)); // r1c3 holds 1, 2, 4
    await tester.pump();
    expect(state().linkStart, (cell: 2, digit: 4));
    await tester.tapAt(mark4(1, 2)); // r2c3 holds 2, 4, 7
    await tester.pump();
    expect(state().links.length, 1);
    await tester.tapAt(mark4(1, 1)); // r2c2 holds 2, 4, 7
    await tester.pump();
    expect(state().links.length, 2, reason: 'the chain continues');
    await tester.tapAt(mark4(1, 1));
    await tester.pump();
    expect(state().linkStart, isNull, reason: 'tapping the start ends it');
    await tester.tap(find.byKey(const ValueKey('numpad-5')));
    await tester.pump();
    expect(state().linkArmed, isFalse, reason: 'a digit key takes over');
    expect(state().links.length, 2);
  });

  testWidgets('an armed swatch paints cells; a digit key takes over', (
    tester,
  ) async {
    await pumpPlay(tester);
    await tester.tap(find.byKey(const ValueKey('paint-2')));
    await tester.pump();
    expect(state().paintArmed, isTrue);
    await tester.tapAt(cellCenter(tester, 0, 0)); // a given cell
    await tester.pump();
    expect(state().cellColors[0], 2);
    expect(state().selected, isNull, reason: 'painting does not select');

    await tester.tap(find.text('지우개'));
    await tester.pump();
    await tester.tapAt(cellCenter(tester, 0, 0));
    await tester.pump();
    expect(state().cellColors[0], 0);

    await tester.tap(find.byKey(const ValueKey('numpad-7')));
    await tester.pump();
    expect(state().paintArmed, isFalse);
    await tester.tapAt(cellCenter(tester, 0, 0));
    await tester.pump();
    expect(state().selected, 0, reason: 'taps select again');
  });

  testWidgets('the top-row button wipes paint and links in one go', (
    tester,
  ) async {
    await pumpPlay(tester);
    final wipe = find.byTooltip('지우기 메뉴');
    await tester.tap(find.byKey(const ValueKey('paint-2')));
    await tester.pump();
    await tester.tapAt(cellCenter(tester, 0, 0));
    await tester.pump();
    expect(state().hasPaint, isTrue);
    await tester.tap(wipe);
    await tester.pumpAndSettle();
    await tester.tap(find.text('모두 지우기'));
    await tester.pumpAndSettle();
    expect(state().hasPaint, isFalse);
    expect(state().links, isEmpty);
    expect(state().canUndo, isTrue);
  });

  testWidgets('a tap on the keypad box beside the keys clears too', (
    tester,
  ) async {
    await pumpPlay(tester);
    await tester.tapAt(cellCenter(tester, 0, 0)); // given 5
    await tester.pump();
    expect(state().highlightOrder, [5]);
    // The box's own padding, left of the first key.
    final pad = tester.getRect(find.byType(NumberPad));
    await tester.tapAt(Offset(pad.left + 3, pad.bottom - 6));
    await tester.pump();
    expect(state().selected, isNull);
    expect(state().highlightOrder, isEmpty);
  });

  testWidgets('the candidate-count buttons toggle their filters', (
    tester,
  ) async {
    await pumpPlay(tester);
    await tester.tap(find.text('후보 2개'));
    await tester.pump();
    expect(state().highlightsNoteCount(2), isTrue);
    expect(state().highlightsNoteCount(3), isFalse);

    await tester.tap(find.text('후보 3개'));
    await tester.pump();
    expect(state().highlightsNoteCount(3), isTrue);

    await tester.tap(find.text('후보 2개'));
    await tester.pump();
    expect(state().highlightsNoteCount(2), isFalse);
    expect(state().highlightsNoteCount(3), isTrue);
  });

  testWidgets('tapping empty space clears the selection and highlight', (
    tester,
  ) async {
    await pumpPlay(tester);
    await tester.tapAt(cellCenter(tester, 0, 0)); // given 5
    await tester.pump();
    expect(state().highlightOrder, [5]);

    // Between the toolbar and the keypad there is nothing but background.
    final toolbar = tester.getRect(find.byType(PlayToolbar));
    final pad = tester.getRect(find.byType(NumberPad));
    await tester.tapAt(
      Offset(toolbar.center.dx, (toolbar.bottom + pad.top) / 2),
    );
    await tester.pump();
    expect(state().selected, isNull);
    expect(state().highlightOrder, isEmpty);
  });
}
