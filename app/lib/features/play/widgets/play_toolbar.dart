import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../settings/settings_provider.dart';
import '../model/play_intent.dart';
import '../model/play_state.dart';
import '../play_controller.dart';
import 'tool_icons.dart';

/// Two rows of icon buttons between the board and the keypad. The upper
/// row is for entering digits: undo, redo, eraser, note mode, fill marks
/// and the what-if. The lower row is for analysis: the paint target, the
/// link tool, the conjugate-pair view, the two candidate-count filters and
/// the wipe menu. Holding a button shows its name.
class PlayToolbar extends ConsumerWidget {
  const PlayToolbar({super.key, required this.state});

  final PlayState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(playControllerProvider.notifier);
    final board = context.boardColors;
    final scheme = Theme.of(context).colorScheme;
    final conjugates = ref.watch(
      settingsProvider.select((s) => s.conjugatePairs),
    );
    final erasing = state.paintArmed && state.paintColor == 0;
    final wipeable = state.hasPaint || state.links.isNotEmpty;

    void tap(PlayIntent intent, {bool select = true}) {
      if (select) {
        HapticFeedback.selectionClick();
      } else {
        HapticFeedback.lightImpact();
      }
      controller.dispatch(intent);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _ToolButton(
                  icon: Icons.undo_rounded,
                  name: '실행취소',
                  enabled: state.canUndo,
                  onTap: () => tap(const Undo(), select: false),
                ),
                _ToolButton(
                  icon: Icons.redo_rounded,
                  name: '다시실행',
                  enabled: state.canRedo,
                  onTap: () => tap(const Redo(), select: false),
                ),
                _ToolButton(
                  glyph: (color) => EraserIcon(color: color, filled: erasing),
                  name: '지우개',
                  active: erasing,
                  onTap: () => tap(const EraseTool()),
                ),
                _ToolButton(
                  glyph: (color) =>
                      PencilIcon(color: color, filled: state.noteMode),
                  name: '메모',
                  active: state.noteMode,
                  onTap: () => tap(const ToggleNoteMode()),
                ),
                _ToolButton(
                  icon: Icons.edit_note_rounded,
                  name: '후보 채움',
                  onTap: () => tap(const FillCandidates(), select: false),
                ),
                // A what-if: digits placed from now on are purple until the
                // player keeps them or goes back to this point.
                _ToolButton(
                  icon: Icons.alt_route_rounded,
                  name: '가정',
                  active: state.hypothesis != null,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    if (state.hypothesis == null) {
                      controller.dispatch(const StartHypothesis());
                    } else {
                      _showHypothesisSheet(context, controller, state);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                // Where an armed palette color lands: the cell, or the
                // nearest pencil mark.
                _ToolButton(
                  icon: state.paintTarget == PaintTarget.note
                      ? Icons.apps_rounded
                      : Icons.apps_outlined,
                  name: '후보 색칠',
                  active: state.paintTarget == PaintTarget.note,
                  onTap: () => tap(
                    SetPaintTarget(
                      state.paintTarget == PaintTarget.note
                          ? PaintTarget.cell
                          : PaintTarget.note,
                    ),
                  ),
                ),
                _ToolButton(
                  icon: state.linkArmed
                      ? Icons.polyline_rounded
                      : Icons.polyline_outlined,
                  name: '연결',
                  active: state.linkArmed,
                  onTap: () => tap(const ToggleLinkTool()),
                ),
                // Shows every conjugate pair of the highlighted digits. A
                // setting, so it survives restarts; toggled from here.
                _ToolButton(
                  icon: Icons.linear_scale_rounded,
                  name: '켤레쌍',
                  active: conjugates,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref
                        .read(settingsProvider.notifier)
                        .setConjugatePairs(!conjugates);
                  },
                ),
                // The active tile takes the board's tile color, so the
                // button and the cells it marks share one look.
                _ToolButton(
                  icon: state.highlightsNoteCount(2)
                      ? Icons.looks_two_rounded
                      : Icons.looks_two_outlined,
                  name: '후보 2개',
                  active: state.highlightsNoteCount(2),
                  activeTile: board.twoNotesTile,
                  activeIcon: board.given,
                  onTap: () => tap(const ToggleNoteCountFilter(2)),
                ),
                _ToolButton(
                  icon: state.highlightsNoteCount(3)
                      ? Icons.looks_3_rounded
                      : Icons.looks_3_outlined,
                  name: '후보 3개',
                  active: state.highlightsNoteCount(3),
                  activeTile: board.threeNotesTile,
                  activeIcon: board.given,
                  onTap: () => tap(const ToggleNoteCountFilter(3)),
                ),
                _ToolButton(
                  icon: Icons.layers_clear_outlined,
                  name: '지우기 메뉴',
                  enabled: wipeable,
                  onTap: () => _showWipeSheet(context, controller, state),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Which marks and links to drop, one layer or all of them.
  void _showWipeSheet(
    BuildContext context,
    PlayController controller,
    PlayState state,
  ) {
    final cells = state.cellColors.where((c) => c != 0).length;
    final marks = state.noteColors.where((c) => c != 0).length;
    void wipe(PlayIntent intent) {
      HapticFeedback.mediumImpact();
      controller.dispatch(intent);
    }

    showAppSheet(
      context,
      title: '지우기',
      items: [
        AppSheetItem(
          icon: Icons.polyline_outlined,
          label: '연결만 지우기',
          detail: '연결 ${state.links.length}개',
          enabled: state.links.isNotEmpty,
          onTap: () => wipe(const ClearLinks()),
        ),
        AppSheetItem(
          icon: Icons.crop_square_rounded,
          label: '칸 색칠만 지우기',
          detail: '칸 $cells개',
          enabled: cells > 0,
          onTap: () => wipe(const ClearCellPaint()),
        ),
        AppSheetItem(
          icon: Icons.apps_rounded,
          label: '후보 색칠만 지우기',
          detail: '후보수 $marks개',
          enabled: marks > 0,
          onTap: () => wipe(const ClearNotePaint()),
        ),
        AppSheetItem(
          icon: Icons.layers_clear_outlined,
          label: '모두 지우기',
          detail: '연결과 색칠 전부',
          destructive: true,
          onTap: () => wipe(const ClearPaint()),
        ),
      ],
    );
  }

  /// Keep or drop everything placed since the what-if began.
  void _showHypothesisSheet(
    BuildContext context,
    PlayController controller,
    PlayState state,
  ) {
    final n = state.hypothesisEntries;
    showAppSheet(
      context,
      title: '가정 중 · $n수',
      items: [
        AppSheetItem(
          icon: Icons.check_rounded,
          label: '확정하기',
          detail: '지금까지 둔 $n수를 그대로 둬요',
          onTap: () {
            HapticFeedback.mediumImpact();
            controller.dispatch(const CommitHypothesis());
          },
        ),
        AppSheetItem(
          icon: Icons.history_rounded,
          label: '시작 시점으로 되돌리기',
          detail: '$n수를 모두 물려요 · 실행취소 가능',
          destructive: true,
          onTap: () {
            HapticFeedback.mediumImpact();
            controller.dispatch(const RevertHypothesis());
          },
        ),
      ],
    );
  }
}

/// Draws a tool's glyph in the given color.
typedef ToolGlyph = Widget Function(Color color);

/// One icon tile. Its name shows on a long press (and to screen readers).
/// The picture is a font [icon] or a hand-drawn [glyph].
class _ToolButton extends StatefulWidget {
  const _ToolButton({
    this.icon,
    this.glyph,
    required this.name,
    required this.onTap,
    this.active = false,
    this.enabled = true,
    this.activeTile,
    this.activeIcon,
  }) : assert((icon == null) != (glyph == null));

  final IconData? icon;
  final ToolGlyph? glyph;
  final String name;
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
    final iconColor = active
        ? (widget.activeIcon ?? scheme.onPrimary)
        : scheme.onSurface;
    // Only the tile shows state (active fill, pressed tint); the ink
    // overlay is off so there is never a second highlight behind it.
    final tileColor = active
        ? (widget.activeTile ?? scheme.primary)
        : _pressed
        ? scheme.surfaceContainerHigh
        : Colors.transparent;
    return Expanded(
      child: Tooltip(
        message: widget.name,
        preferBelow: false,
        child: Semantics(
          button: true,
          enabled: widget.enabled,
          toggled: active,
          label: widget.name,
          child: InkWell(
            onTap: widget.enabled ? widget.onTap : null,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            splashFactory: NoSplash.splashFactory,
            borderRadius: BorderRadius.circular(14),
            child: Opacity(
              opacity: widget.enabled ? 1 : 0.35,
              child: SizedBox(
                height: 48,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: 44,
                    height: 40,
                    decoration: BoxDecoration(
                      color: tileColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child:
                          widget.glyph?.call(iconColor) ??
                          Icon(widget.icon, size: 24, color: iconColor),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
