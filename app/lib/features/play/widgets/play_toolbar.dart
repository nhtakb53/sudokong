import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../model/play_intent.dart';
import '../model/play_state.dart';
import '../play_controller.dart';

/// Actions between the board and the keypad, evenly spread across the
/// board width: undo, redo, erase, note mode, the paint target, fill
/// candidates, and the two candidate-count filters.
class PlayToolbar extends ConsumerWidget {
  const PlayToolbar({super.key, required this.state});

  final PlayState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(playControllerProvider.notifier);
    final board = context.boardColors;
    final scheme = Theme.of(context).colorScheme;
    final selected = state.selected;
    final canErase =
        selected != null &&
        !state.isGiven(selected) &&
        (state.values[selected] != 0 || state.notes[selected] != 0);
    // Boxed like the keypad, so the two controls read as one console.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            _ToolButton(
              icon: Icons.undo_rounded,
              label: '실행취소',
              enabled: state.canUndo,
              onTap: () {
                HapticFeedback.lightImpact();
                controller.dispatch(const Undo());
              },
            ),
            _ToolButton(
              icon: Icons.redo_rounded,
              label: '다시 실행',
              enabled: state.canRedo,
              onTap: () {
                HapticFeedback.lightImpact();
                controller.dispatch(const Redo());
              },
            ),
            _ToolButton(
              icon: Icons.backspace_outlined,
              label: '지우기',
              enabled: canErase,
              onTap: () {
                HapticFeedback.lightImpact();
                controller.dispatch(const Erase());
              },
            ),
            _ToolButton(
              icon: state.noteMode ? Icons.edit_rounded : Icons.edit_outlined,
              label: '메모',
              active: state.noteMode,
              onTap: () {
                HapticFeedback.selectionClick();
                controller.dispatch(const ToggleNoteMode());
              },
            ),
            // Where an armed palette color lands: the cell, or the
            // nearest pencil mark.
            _ToolButton(
              icon: state.paintTarget == PaintTarget.note
                  ? Icons.apps_rounded
                  : Icons.apps_outlined,
              label: '후보 색칠',
              active: state.paintTarget == PaintTarget.note,
              onTap: () {
                HapticFeedback.selectionClick();
                controller.dispatch(
                  SetPaintTarget(
                    state.paintTarget == PaintTarget.note
                        ? PaintTarget.cell
                        : PaintTarget.note,
                  ),
                );
              },
            ),
            _ToolButton(
              icon: Icons.edit_note_rounded,
              label: '후보 채움',
              onTap: () {
                HapticFeedback.lightImpact();
                controller.dispatch(const FillCandidates());
              },
            ),
            // The active tile takes the board's tile color, so the button
            // and the cells it marks share one look.
            _ToolButton(
              icon: state.highlightsNoteCount(2)
                  ? Icons.looks_two_rounded
                  : Icons.looks_two_outlined,
              label: '후보 2개',
              active: state.highlightsNoteCount(2),
              activeTile: board.twoNotesTile,
              activeIcon: board.given,
              onTap: () {
                HapticFeedback.selectionClick();
                controller.dispatch(const ToggleNoteCountFilter(2));
              },
            ),
            _ToolButton(
              icon: state.highlightsNoteCount(3)
                  ? Icons.looks_3_rounded
                  : Icons.looks_3_outlined,
              label: '후보 3개',
              active: state.highlightsNoteCount(3),
              activeTile: board.threeNotesTile,
              activeIcon: board.given,
              onTap: () {
                HapticFeedback.selectionClick();
                controller.dispatch(const ToggleNoteCountFilter(3));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatefulWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.enabled = true,
    this.activeTile,
    this.activeIcon,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool enabled;

  /// Tile and icon colors while [active]; the primary color otherwise.
  final Color? activeTile;
  final Color? activeIcon;

  @override
  State<_ToolButton> createState() => _ToolButtonState();
}

class _ToolButtonState extends State<_ToolButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = widget.active;
    final customTile = widget.activeTile;
    final iconColor = active
        ? (widget.activeIcon ?? scheme.onPrimary)
        : scheme.onSurface;
    final labelColor = active
        ? (customTile == null ? scheme.primary : scheme.onSurface)
        : scheme.onSurfaceVariant;
    // Only the icon tile shows state (active fill, pressed tint); the ink
    // overlay is off so there is never a second highlight behind it.
    final tileColor = active
        ? (customTile ?? scheme.primary)
        : _pressed
        ? scheme.surfaceContainerHigh
        : Colors.transparent;
    return Expanded(
      child: Semantics(
        button: true,
        enabled: widget.enabled,
        toggled: active,
        label: widget.label,
        child: InkWell(
          onTap: widget.enabled ? widget.onTap : null,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
          borderRadius: BorderRadius.circular(14),
          child: Opacity(
            opacity: widget.enabled ? 1 : 0.35,
            child: SizedBox(
              height: 68,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: 44,
                    height: 40,
                    decoration: BoxDecoration(
                      color: tileColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, size: 24, color: iconColor),
                  ),
                  const SizedBox(height: 4),
                  // Scales a label down rather than wrapping on narrow slots.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: labelColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
