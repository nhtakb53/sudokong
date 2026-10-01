import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../help/glossary_screen.dart';
import '../play/game_timer.dart';
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
    final clock = ref.watch(gameTimerProvider.select((t) => t.label));
    final filled = state == null ? 0 : state.values.where((v) => v != 0).length;
    final scheme = Theme.of(context).colorScheme;

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
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                const Spacer(),
                IconButton(
                  tooltip: '설정',
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '용어 설명',
                  icon: const Icon(Icons.help_outline_rounded),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const GlossaryScreen(),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 96,
                        height: 96,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      '스도콩',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '기본에 충실한 스도쿠',
                      style: TextStyle(
                        fontSize: 15,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (canResume) ...[
                      Text(
                        '진행 중인 게임 · $clock · $filled/81 채움',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    FilledButton.icon(
                      key: const ValueKey('home-resume'),
                      onPressed: canResume ? open : null,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('이어하기', style: TextStyle(fontSize: 17)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      key: const ValueKey('home-new'),
                      onPressed: game.isLoading ? null : startNew,
                      icon: const Icon(Icons.add_rounded),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('새 게임', style: TextStyle(fontSize: 17)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
