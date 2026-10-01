import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game_timer.dart';

/// Elapsed time with a pause control. Only this widget rebuilds on ticks.
class TimerChip extends ConsumerWidget {
  const TimerChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(gameTimerProvider);
    final scheme = Theme.of(context).colorScheme;
    final finished = timer.finished;
    return Semantics(
      button: !finished,
      label: finished
          ? '완료'
          : timer.paused
          ? '계속'
          : '일시정지',
      value: timer.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: finished
            ? null
            : () {
                final notifier = ref.read(gameTimerProvider.notifier);
                timer.paused ? notifier.resume() : notifier.pause();
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                finished
                    ? Icons.check_rounded
                    : timer.paused
                    ? Icons.play_arrow_rounded
                    : Icons.pause_rounded,
                size: 20,
                color: finished ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                timer.label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
