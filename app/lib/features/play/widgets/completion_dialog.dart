import 'package:flutter/material.dart';

/// Shown once when the board is solved.
class CompletionDialog extends StatelessWidget {
  const CompletionDialog({super.key, this.timeLabel, required this.onNewGame});

  /// Elapsed time, or null when the clock is hidden.
  final String? timeLabel;
  final VoidCallback onNewGame;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      icon: Icon(Icons.check_circle_rounded, color: scheme.primary, size: 44),
      title: const Text('다 풀었어요'),
      content: timeLabel == null
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('걸린 시간', style: TextStyle(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text(
                  timeLabel!,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            onNewGame();
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('새 게임'),
        ),
      ],
    );
  }
}
