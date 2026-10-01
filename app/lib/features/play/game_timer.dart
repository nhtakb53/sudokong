import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Elapsed time of the current game, kept apart from the board state so a
/// tick never rebuilds the board.
@immutable
class GameTimerState {
  const GameTimerState({
    this.seconds = 0,
    this.paused = false,
    this.finished = false,
  });

  final int seconds;
  final bool paused;

  /// The game was solved: the clock is stopped for good until [GameTimer.reset].
  final bool finished;

  GameTimerState copyWith({int? seconds, bool? paused, bool? finished}) =>
      GameTimerState(
        seconds: seconds ?? this.seconds,
        paused: paused ?? this.paused,
        finished: finished ?? this.finished,
      );

  /// `mm:ss`, or `h:mm:ss` past an hour.
  String get label {
    final h = seconds ~/ 3600;
    final m = (seconds ~/ 60) % 60;
    final s = seconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }
}

final gameTimerProvider = NotifierProvider<GameTimer, GameTimerState>(
  GameTimer.new,
);

class GameTimer extends Notifier<GameTimerState> {
  Timer? _ticker;

  @override
  GameTimerState build() {
    ref.onDispose(() => _ticker?.cancel());
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.paused) state = state.copyWith(seconds: state.seconds + 1);
    });
    return const GameTimerState();
  }

  void pause() {
    if (!state.paused) state = state.copyWith(paused: true);
  }

  void resume() {
    if (state.paused && !state.finished) state = state.copyWith(paused: false);
  }

  /// Stops the clock at the solve time; [resume] no longer restarts it.
  void stop() {
    if (!state.finished) state = state.copyWith(paused: true, finished: true);
  }

  void reset() => state = const GameTimerState();
}
