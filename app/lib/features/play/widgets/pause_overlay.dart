import 'package:flutter/material.dart';

import 'board_painter.dart';

/// Stands in for the board while the game is paused, so the puzzle is not
/// visible and the layout does not move.
class PauseOverlay extends StatelessWidget {
  const PauseOverlay({super.key, required this.onResume});

  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: kBoardAspectRatio,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(kBoardCornerRadius),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pause_circle_outline_rounded,
              size: 56,
              color: scheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              '일시정지',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onResume,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('계속'),
            ),
          ],
        ),
      ),
    );
  }
}
