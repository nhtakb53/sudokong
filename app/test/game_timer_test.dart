import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudokong/features/play/game_timer.dart';

void main() {
  test('counts seconds, pauses, resumes and resets', () {
    fakeAsync((async) {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      GameTimerState state() => container.read(gameTimerProvider);
      final timer = container.read(gameTimerProvider.notifier);

      expect(state().paused, isTrue, reason: 'starts paused until play');
      timer.resume();
      expect(state().seconds, 0);
      async.elapse(const Duration(seconds: 3));
      expect(state().seconds, 3);

      timer.pause();
      async.elapse(const Duration(seconds: 5));
      expect(state().seconds, 3, reason: 'paused clock does not advance');

      timer.resume();
      async.elapse(const Duration(seconds: 2));
      expect(state().seconds, 5);

      timer.reset();
      expect(state().seconds, 0);
      expect(state().paused, isFalse);
      container.dispose();
    });
  });

  test('a stopped clock ignores resume until reset', () {
    fakeAsync((async) {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      GameTimerState state() => container.read(gameTimerProvider);
      final timer = container.read(gameTimerProvider.notifier);

      timer.resume();
      async.elapse(const Duration(seconds: 4));
      timer.stop();
      expect(state().finished, isTrue);
      expect(state().paused, isTrue);

      timer.resume();
      async.elapse(const Duration(seconds: 3));
      expect(state().seconds, 4, reason: 'finished clock stays stopped');

      timer.reset();
      expect(state().finished, isFalse);
      async.elapse(const Duration(seconds: 1));
      expect(state().seconds, 1);
      container.dispose();
    });
  });

  test('formats as mm:ss and h:mm:ss', () {
    expect(const GameTimerState(seconds: 0).label, '00:00');
    expect(const GameTimerState(seconds: 754).label, '12:34');
    expect(const GameTimerState(seconds: 3600 + 65).label, '1:01:05');
  });
}
