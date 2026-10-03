// Renders screens at phone resolution and writes PNGs, so UI can be
// reviewed without a device. Run with:
//   SUDOKONG_SCREENSHOT=1 flutter test test/screenshot
// Output lands in build/screenshots/.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sudokong/core/theme/app_theme.dart';
import 'package:sudokong/core/theme/color_theme.dart';
import 'package:sudokong/features/help/glossary_screen.dart';
import 'package:sudokong/features/home/home_screen.dart';
import 'package:sudokong/features/play/model/play_intent.dart';
import 'package:sudokong/features/play/model/play_reducer.dart';
import 'package:sudokong/features/play/model/play_state.dart';
import 'package:sudokong/features/play/game_timer.dart';
import 'package:sudokong/features/play/play_controller.dart';
import 'package:sudokong/features/play/play_screen.dart';
import 'package:sudokong/features/settings/settings_provider.dart';
import 'package:sudokong/features/settings/settings_screen.dart';
import 'package:sudoku_engine/sudoku_engine.dart';

final bool _enabled = Platform.environment['SUDOKONG_SCREENSHOT'] == '1';

const _puzzle =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

/// A realistic mid-game state: a few entries, one conflict, some notes and
/// a selected cell.
PlayState _sampleState() {
  var s = PlayState.fromPuzzle(
    const GeneratedPuzzle(
      puzzle: _puzzle,
      solution: _solution,
      givens: 30,
      seed: 1,
    ),
  );
  s = reduce(s, const SelectCell(2));
  s = reduce(s, const EnterDigit(4));
  s = reduce(s, const SelectCell(38));
  s = reduce(s, const EnterDigit(5));
  s = reduce(s, const SelectCell(20));
  s = reduce(s, const EnterDigit(3)); // conflicts with the given 3 in row 3
  final notes = Uint16List(81);
  notes[3] = 0x02 | 0x20; // 2, 6
  notes[4] = 0x02 | 0x08 | 0x20; // 2, 4, 6
  notes[40] = 0x10 | 0x40; // 5, 7
  notes[60] = 0x01 | 0x04 | 0x40; // 1, 3, 7
  s = s.copyWith(notes: notes);
  return reduce(s, const SelectCell(39));
}

/// Test doubles never write to disk, so no save timer is left pending.
abstract class _QuietPlayController extends PlayController {
  @override
  void scheduleSave() {}
}

class _FixedPlayController extends _QuietPlayController {
  @override
  Future<PlayState> build() async => _sampleState();
}

class _FreshPlayController extends _QuietPlayController {
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

class _NoteModePlayController extends _QuietPlayController {
  @override
  Future<PlayState> build() async =>
      reduce(_sampleState(), const ToggleNoteMode());
}

/// One cell away from solved, with that cell selected.
class _AlmostDonePlayController extends _QuietPlayController {
  @override
  Future<PlayState> build() async {
    final cells = GridCodec.parse(_solution);
    cells[2] = 0;
    return PlayState(
      givens: GridCodec.parse(_puzzle),
      solution: GridCodec.parse(_solution),
      values: cells,
      notes: Uint16List(81),
      seed: 1,
      selected: 2,
    );
  }
}

class _CandidatesPlayController extends _QuietPlayController {
  @override
  Future<PlayState> build() async =>
      reduce(_sampleState(), const FillCandidates());
}

/// All candidates filled and every digit highlighted in its own color.
class _MultiPlayController extends _QuietPlayController {
  @override
  Future<PlayState> build() async {
    var s = reduce(_sampleState(), const FillCandidates()); // 8 is lit
    for (final d in [3, 5, 1, 7, 2, 9, 4, 6]) {
      s = reduce(s, ToggleHighlight(d));
    }
    return s;
  }
}

/// A few painted cells and marks, with a color still armed.
class _PaintedPlayController extends _QuietPlayController {
  @override
  Future<PlayState> build() async {
    var s = reduce(_sampleState(), const FillCandidates());
    for (final (cell, color) in [(0, 2), (1, 2), (9, 4), (30, 6), (70, 3)]) {
      s = reduce(s, PickPaint(color));
      s = reduce(s, PaintCell(cell));
    }
    s = reduce(s, const SetPaintTarget(PaintTarget.note));
    for (final (cell, digit, color) in [(2, 4, 5), (11, 4, 5), (11, 7, 3)]) {
      s = reduce(s, PickPaint(color));
      s = reduce(s, PaintNote(cell, digit));
    }
    return s;
  }
}

/// All candidates filled and a chain of links drawn with the tool armed.
class _LinkedPlayController extends _QuietPlayController {
  @override
  Future<PlayState> build() async {
    var s = reduce(_sampleState(), const FillCandidates());
    s = reduce(s, const ToggleLinkTool());
    for (final (cell, digit) in [
      (10, 2),
      (10, 7),
      (11, 7),
      (15, 7),
      (15, 3),
      (16, 3),
    ]) {
      s = reduce(s, TapForLink(cell, digit));
    }
    return s;
  }
}

/// A what-if in progress with two purple digits, 7 highlighted.
class _WhatIfPlayController extends _QuietPlayController {
  @override
  Future<PlayState> build() async {
    var s = reduce(_sampleState(), const FillCandidates());
    s = reduce(s, const StartHypothesis());
    s = reduce(s, const SelectCell(3));
    s = reduce(s, const EnterDigit(6));
    s = reduce(s, const SelectCell(10));
    s = reduce(s, const EnterDigit(2));
    return reduce(s, const HoldDigit(7));
  }
}

/// All candidates filled, with both count filters switched on.
class _FilteredPlayController extends _QuietPlayController {
  @override
  Future<PlayState> build() async {
    var s = reduce(_sampleState(), const FillCandidates());
    s = reduce(s, const ToggleNoteCountFilter(2));
    return reduce(s, const ToggleNoteCountFilter(3));
  }
}

Future<void> _loadFonts() async {
  final pretendard = FontLoader('Pretendard');
  for (final file in [
    'Pretendard-Regular.otf',
    'Pretendard-Medium.otf',
    'Pretendard-SemiBold.otf',
    'Pretendard-Bold.otf',
  ]) {
    final bytes = await File('assets/fonts/$file').readAsBytes();
    pretendard.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await pretendard.load();

  final flutterRoot =
      Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.path;
  final icons = File(
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons');
    final bytes = await icons.readAsBytes();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
  }
}

Future<void> _capture(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byType(RepaintBoundary).first,
  );
  final image = await boundary.toImage(pixelRatio: 2.75);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final out = File('build/screenshots/$name.png')..createSync(recursive: true);
  out.writeAsBytesSync(bytes!.buffer.asUint8List());
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required Brightness brightness,
  required Widget home,
  String? seededSettings,
  bool candidates = false,
  bool filters = false,
  bool whatIf = false,
  bool links = false,
  bool paint = false,
  bool multi = false,
  bool noteMode = false,
  bool paused = false,
  bool almostDone = false,
  bool fresh = false,
  Size physicalSize = const Size(1080, 2340),
  FakeViewPadding padding = FakeViewPadding.zero,
  double textScale = 1,
}) async {
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = 2.75;
  tester.view.padding = padding;
  addTearDown(tester.view.reset);

  final prefs = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(),
  );
  if (seededSettings != null) {
    await prefs.setString(SettingsNotifier.storageKey, seededSettings);
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        gameTimerProvider.overrideWith(
          paused ? _PausedTimer.new : _StillTimer.new,
        ),
        playControllerProvider.overrideWith(
          fresh
              ? _FreshPlayController.new
              : almostDone
              ? _AlmostDonePlayController.new
              : noteMode
              ? _NoteModePlayController.new
              : filters
              ? _FilteredPlayController.new
              : whatIf
              ? _WhatIfPlayController.new
              : links
              ? _LinkedPlayController.new
              : paint
              ? _PaintedPlayController.new
              : multi
              ? _MultiPlayController.new
              : candidates
              ? _CandidatesPlayController.new
              : _FixedPlayController.new,
        ),
      ],
      child: RepaintBoundary(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(ColorTheme.classic, brightness),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: home,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// A clock that never ticks, so tests end with no pending timers.
class _StillTimer extends GameTimer {
  @override
  GameTimerState build() => const GameTimerState();
}

class _PausedTimer extends GameTimer {
  @override
  GameTimerState build() => const GameTimerState(seconds: 754, paused: true);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    if (_enabled) await _loadFonts();
  });

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  for (final brightness in Brightness.values) {
    testWidgets('play screen (${brightness.name})', (tester) async {
      await _pumpApp(tester, brightness: brightness, home: const PlayScreen());
      await tester.runAsync(() => _capture(tester, 'play_${brightness.name}'));
    }, skip: !_enabled);

    testWidgets('play screen on an iPhone (${brightness.name})', (
      tester,
    ) async {
      // iPhone 15 safe areas at the test ratio: 59 dp above, 34 dp below.
      await _pumpApp(
        tester,
        brightness: brightness,
        home: const PlayScreen(),
        padding: const FakeViewPadding(top: 162, bottom: 94),
      );
      await tester.runAsync(
        () => _capture(tester, 'play_iphone_${brightness.name}'),
      );
    }, skip: !_enabled);

    testWidgets('play screen with all candidates (${brightness.name})', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        brightness: brightness,
        home: const PlayScreen(),
        candidates: true,
      );
      await tester.runAsync(
        () => _capture(tester, 'play_candidates_${brightness.name}'),
      );
    }, skip: !_enabled);

    testWidgets('play screen, circle note highlight (${brightness.name})', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        brightness: brightness,
        home: const PlayScreen(),
        candidates: true,
        seededSettings: '{"v":1,"noteHighlightShape":"circle"}',
      );
      await tester.runAsync(
        () => _capture(tester, 'play_candidates_circle_${brightness.name}'),
      );
    }, skip: !_enabled);

    testWidgets('play screen, candidate-count filters (${brightness.name})', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        brightness: brightness,
        home: const PlayScreen(),
        filters: true,
      );
      await tester.runAsync(
        () => _capture(tester, 'play_filters_${brightness.name}'),
      );
    }, skip: !_enabled);

    testWidgets('play screen, links (${brightness.name})', (tester) async {
      await _pumpApp(
        tester,
        brightness: brightness,
        home: const PlayScreen(),
        links: true,
      );
      await tester.runAsync(
        () => _capture(tester, 'play_links_${brightness.name}'),
      );
    }, skip: !_enabled);

    testWidgets('play screen, paint mode (${brightness.name})', (tester) async {
      await _pumpApp(
        tester,
        brightness: brightness,
        home: const PlayScreen(),
        paint: true,
      );
      await tester.runAsync(
        () => _capture(tester, 'play_paint_${brightness.name}'),
      );
    }, skip: !_enabled);

    testWidgets('what-if with conjugate pairs (${brightness.name})', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        brightness: brightness,
        home: const PlayScreen(),
        whatIf: true,
        seededSettings: '{"v":1,"conjugatePairs":true}',
      );
      await tester.runAsync(
        () => _capture(tester, 'play_whatif_${brightness.name}'),
      );
    }, skip: !_enabled);

    testWidgets('wipe sheet (${brightness.name})', (tester) async {
      await _pumpApp(
        tester,
        brightness: brightness,
        home: const PlayScreen(),
        paint: true,
      );
      await tester.tap(find.byTooltip('지우기 메뉴'));
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => _capture(tester, 'wipe_sheet_${brightness.name}'),
      );
    }, skip: !_enabled);

    testWidgets('play screen, nine digits highlighted (${brightness.name})', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        brightness: brightness,
        home: const PlayScreen(),
        multi: true,
      );
      await tester.runAsync(
        () => _capture(tester, 'play_multi_${brightness.name}'),
      );
    }, skip: !_enabled);

    testWidgets('home screen (${brightness.name})', (tester) async {
      await _pumpApp(
        tester,
        brightness: brightness,
        home: const HomeScreen(),
        candidates: true,
      );
      // Let the logo decode before the capture.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pump();
      await tester.runAsync(() => _capture(tester, 'home_${brightness.name}'));
    }, skip: !_enabled);

    for (final variant in [
      (name: 'fresh', size: const Size(1080, 2340), scale: 1.0, fresh: true),
      (name: 'compact', size: const Size(880, 1568), scale: 1.0, fresh: false),
      (
        name: 'large_text',
        size: const Size(1080, 2340),
        scale: 2.0,
        fresh: false,
      ),
      (
        name: 'landscape',
        size: const Size(2340, 1080),
        scale: 1.0,
        fresh: false,
      ),
    ]) {
      testWidgets('home screen ${variant.name} (${brightness.name})', (
        tester,
      ) async {
        await _pumpApp(
          tester,
          brightness: brightness,
          home: const HomeScreen(),
          fresh: variant.fresh,
          physicalSize: variant.size,
          textScale: variant.scale,
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)),
        );
        await tester.pump();
        await tester.runAsync(
          () => _capture(tester, 'home_${variant.name}_${brightness.name}'),
        );
      }, skip: !_enabled);
    }

    testWidgets('glossary screen (${brightness.name})', (tester) async {
      await _pumpApp(
        tester,
        brightness: brightness,
        home: const GlossaryScreen(),
      );
      await tester.runAsync(
        () => _capture(tester, 'glossary_${brightness.name}'),
      );
    }, skip: !_enabled);

    testWidgets('play screen, note mode on (${brightness.name})', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        brightness: brightness,
        home: const PlayScreen(),
        noteMode: true,
      );
      await tester.runAsync(
        () => _capture(tester, 'play_notemode_${brightness.name}'),
      );
    }, skip: !_enabled);

    testWidgets('play screen, paused (${brightness.name})', (tester) async {
      await _pumpApp(
        tester,
        brightness: brightness,
        home: const PlayScreen(),
        paused: true,
      );
      await tester.runAsync(
        () => _capture(tester, 'play_paused_${brightness.name}'),
      );
    }, skip: !_enabled);

    testWidgets('completion dialog (${brightness.name})', (tester) async {
      await _pumpApp(
        tester,
        brightness: brightness,
        home: const PlayScreen(),
        almostDone: true,
      );
      await tester.tap(find.byKey(const ValueKey('numpad-4')));
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => _capture(tester, 'play_completed_${brightness.name}'),
      );
    }, skip: !_enabled);

    testWidgets('play screen, one-row keypad (${brightness.name})', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        brightness: brightness,
        home: const PlayScreen(),
        seededSettings: '{"v":1,"numberPadLayout":"oneRow"}',
      );
      await tester.runAsync(
        () => _capture(tester, 'play_onerow_${brightness.name}'),
      );
    }, skip: !_enabled);

    testWidgets('settings screen (${brightness.name})', (tester) async {
      await _pumpApp(
        tester,
        brightness: brightness,
        home: const SettingsScreen(),
      );
      await tester.runAsync(
        () => _capture(tester, 'settings_${brightness.name}'),
      );
    }, skip: !_enabled);
  }
}
