import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/board_colors.dart';
import '../help/glossary_screen.dart';
import '../play/play_controller.dart';
import '../play/play_screen.dart';
import '../settings/settings_screen.dart';

/// Where the app opens: continue the game in progress, or start a new one.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(playControllerProvider);
    final state = game.value;
    final canResume = state?.hasProgress ?? false;
    final colors = HomeColors.of(context);

    Future<void> open() =>
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => const PlayScreen()));

    Future<void> startNew() async {
      if (canResume) {
        final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('새 게임을 시작할까요?'),
            content: const Text('진행 중인 퍼즐은 사라집니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('새 게임'),
              ),
            ],
          ),
        );
        if (ok != true) return;
      }
      await ref.read(playControllerProvider.notifier).newGame();
      if (context.mounted) await open();
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.4;
            final wide = constraints.maxWidth >= 700 && !largeText;
            final compact = constraints.maxHeight < 700 || largeText;
            final heroSize = wide
                ? (constraints.maxHeight * 0.65).clamp(180.0, 260.0)
                : compact
                ? (constraints.maxHeight * 0.22).clamp(112.0, 154.0)
                : (constraints.maxHeight * 0.32).clamp(190.0, 280.0);
            final resume = _HomeAction(
              buttonKey: const ValueKey('home-resume'),
              label: '이어하기',
              icon: Icons.play_arrow_rounded,
              primary: canResume,
              onPressed: canResume ? open : null,
              colors: colors,
              compact: compact,
            );
            final newGame = _HomeAction(
              buttonKey: const ValueKey('home-new'),
              label: '새 게임',
              icon: Icons.add_rounded,
              primary: !canResume,
              onPressed: game.isLoading ? null : startNew,
              colors: colors,
              compact: compact,
            );

            final playCard = _PlayCard(
              canResume: canResume,
              colors: colors,
              compact: compact,
              primaryAction: newGame,
              secondaryAction: resume,
            );
            final hero = _HomeMascot(size: heroSize, colors: colors);
            Widget reveal(Widget child) => TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 10 * (1 - value)),
                  child: child,
                ),
              ),
              child: child,
            );

            return CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: wide ? 880 : 468),
                      child: Padding(
                        padding: compact
                            ? const EdgeInsets.fromLTRB(20, 8, 20, 16)
                            : const EdgeInsets.fromLTRB(24, 12, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                _BrandMark(colors: colors),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'SUDOKONG',
                                    style: TextStyle(
                                      color: colors.ink,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.8,
                                    ),
                                  ),
                                ),
                                _HomeIconButton(
                                  tooltip: '설정',
                                  icon: Icons.settings_outlined,
                                  colors: colors,
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const SettingsScreen(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _HomeIconButton(
                                  tooltip: '용어 설명',
                                  icon: Icons.help_outline_rounded,
                                  colors: colors,
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const GlossaryScreen(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: compact ? 12 : 24),
                            // The mascot and the card share the free
                            // height, weighted toward the bottom; side by
                            // side on a wide screen.
                            if (wide) ...[
                              const Spacer(),
                              reveal(
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(child: Center(child: hero)),
                                    const SizedBox(width: 32),
                                    Expanded(child: playCard),
                                  ],
                                ),
                              ),
                              const Spacer(),
                            ] else ...[
                              // The free height splits in three: above
                              // the mascot, between it and the card, and
                              // below the card. The card sits a third of
                              // the way up, the mascot well above it.
                              const Spacer(),
                              Center(child: hero),
                              SizedBox(height: compact ? 16 : 28),
                              const Spacer(),
                              reveal(playCard),
                              const Spacer(),
                            ],
                            if (!wide) ...[
                              SizedBox(height: compact ? 12 : 24),
                              Center(
                                child: Text(
                                  'DALKONG-E UNIVERSE',
                                  style: TextStyle(
                                    color: colors.muted,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.colors});

  final HomeColors colors;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: 22,
      child: GridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 3,
        crossAxisSpacing: 3,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: List.generate(
          9,
          (i) => DecoratedBox(
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: i == 4 ? 1 : 0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    ),
  );
}

class _HomeIconButton extends StatelessWidget {
  const _HomeIconButton({
    required this.tooltip,
    required this.icon,
    required this.colors,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final HomeColors colors;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon, size: 21),
    style: IconButton.styleFrom(
      foregroundColor: colors.ink,
      backgroundColor: colors.surface,
      side: BorderSide(color: colors.line),
      minimumSize: const Size.square(44),
    ),
  );
}

class _HomeMascot extends StatelessWidget {
  const _HomeMascot({required this.size, required this.colors});

  final double size;
  final HomeColors colors;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.all(size * 0.075),
            child: Transform.rotate(
              angle: -0.08,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(size * 0.16),
                child: CustomPaint(painter: _HeroGridPainter(colors)),
              ),
            ),
          ),
        ),
        Image.asset(
          'assets/images/dalkong.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        ),
      ],
    ),
  );
}

/// Decorative echo of the board, using the same peer and selected colors.
class _HeroGridPainter extends CustomPainter {
  const _HeroGridPainter(this.colors);

  final HomeColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = colors.halo);
    final cell = size.width / 3;
    canvas.drawRect(
      Rect.fromLTWH(cell * 2, 0, cell, cell),
      Paint()..color = colors.haloAccent,
    );
    final line = Paint()
      ..color = colors.background.withValues(alpha: 0.55)
      ..strokeWidth = 2;
    for (var i = 1; i < 3; i++) {
      canvas.drawLine(Offset(cell * i, 0), Offset(cell * i, size.height), line);
      canvas.drawLine(Offset(0, cell * i), Offset(size.width, cell * i), line);
    }
  }

  @override
  bool shouldRepaint(_HeroGridPainter oldDelegate) =>
      oldDelegate.colors.halo != colors.halo ||
      oldDelegate.colors.haloAccent != colors.haloAccent ||
      oldDelegate.colors.background != colors.background;
}

class _PlayCard extends StatelessWidget {
  const _PlayCard({
    required this.canResume,
    required this.colors,
    required this.compact,
    required this.primaryAction,
    required this.secondaryAction,
  });

  final bool canResume;
  final HomeColors colors;
  final bool compact;
  final Widget primaryAction;
  final Widget secondaryAction;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(compact ? 16 : 20),
    decoration: BoxDecoration(
      color: colors.surface,
      border: Border.all(color: colors.line),
      borderRadius: BorderRadius.circular(28),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [primaryAction, const SizedBox(height: 10), secondaryAction],
    ),
  );
}

class _HomeAction extends StatelessWidget {
  const _HomeAction({
    required this.buttonKey,
    required this.label,
    required this.icon,
    required this.primary,
    required this.onPressed,
    required this.colors,
    this.compact = false,
  });

  final Key buttonKey;
  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback? onPressed;
  final HomeColors colors;
  final bool compact;

  @override
  Widget build(BuildContext context) => FilledButton(
    key: buttonKey,
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: primary ? colors.accent : colors.background,
      foregroundColor: primary ? colors.onAccent : colors.ink,
      disabledBackgroundColor: colors.line.withValues(alpha: 0.35),
      disabledForegroundColor: colors.muted.withValues(alpha: 0.65),
      minimumSize: Size.fromHeight(compact ? 52 : 56),
      padding: EdgeInsets.symmetric(
        horizontal: 18,
        vertical: compact ? 12 : 15,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      textStyle: Theme.of(context).textTheme.labelLarge
          ?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
    ),
    child: Row(
      children: [
        Icon(icon, size: 23),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        if (onPressed != null)
          const Icon(Icons.arrow_forward_rounded, size: 19),
      ],
    ),
  );
}
