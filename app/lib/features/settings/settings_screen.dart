import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_settings.dart';
import 'settings_provider.dart';
import 'widgets/settings_section.dart';
import 'widgets/theme_mode_picker.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(title: Text('설정')),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList.list(
              children: [
                SettingsSection(
                  title: '화면',
                  children: [
                    SettingsRow(
                      title: '테마',
                      child: ThemeModePicker(
                        value: settings.themeMode,
                        colorTheme: settings.colorTheme,
                        onChanged: notifier.setThemeMode,
                      ),
                    ),
                    // 색상 테마 행은 팔레트가 둘 이상 생길 때 여기에 추가한다.
                  ],
                ),
                const SizedBox(height: 24),
                SettingsSection(
                  title: '게임',
                  children: [
                    SettingsRow(
                      title: '입력 방식',
                      trailing: _Choice<InputMode>(
                        segments: const [
                          ButtonSegment(
                            value: InputMode.cellFirst,
                            label: Text('칸 먼저'),
                          ),
                          ButtonSegment(
                            value: InputMode.digitFirst,
                            label: Text('숫자 먼저'),
                          ),
                        ],
                        selected: settings.inputMode,
                        onChanged: notifier.setInputMode,
                      ),
                    ),
                    SettingsRow(
                      title: '숫자 키패드',
                      trailing: _Choice<NumberPadLayout>(
                        segments: const [
                          ButtonSegment(
                            value: NumberPadLayout.oneRow,
                            label: Text('1줄'),
                          ),
                          ButtonSegment(
                            value: NumberPadLayout.twoRows,
                            label: Text('2줄'),
                          ),
                        ],
                        selected: settings.numberPadLayout,
                        onChanged: notifier.setNumberPadLayout,
                      ),
                    ),
                    SettingsRow(
                      title: '꾹 누르기 시간',
                      trailing: Text(
                        '${settings.longPressMs}ms',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      child: Slider(
                        value: settings.longPressMs.toDouble(),
                        min: AppSettings.minLongPressMs.toDouble(),
                        max: AppSettings.maxLongPressMs.toDouble(),
                        divisions:
                            (AppSettings.maxLongPressMs -
                                AppSettings.minLongPressMs) ~/
                            50,
                        label: '${settings.longPressMs}ms',
                        onChanged: (v) =>
                            notifier.setLongPressMs((v / 50).round() * 50),
                      ),
                    ),
                    SettingsRow(
                      title: '후보 강조 모양',
                      trailing: _Choice<NoteHighlightShape>(
                        segments: const [
                          ButtonSegment(
                            value: NoteHighlightShape.roundedSquare,
                            label: Text('둥근 네모'),
                          ),
                          ButtonSegment(
                            value: NoteHighlightShape.circle,
                            label: Text('원'),
                          ),
                        ],
                        selected: settings.noteHighlightShape,
                        onChanged: notifier.setNoteHighlightShape,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A two-way choice with a fixed width, so the controls in one section line
/// up on their left edge as well as their right.
class _Choice<T> extends StatelessWidget {
  const _Choice({
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  static const double width = 180;

  final List<ButtonSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: SegmentedButton<T>(
        showSelectedIcon: false,
        expandedInsets: EdgeInsets.zero,
        style: const ButtonStyle(visualDensity: VisualDensity.compact),
        segments: segments,
        selected: {selected},
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );
  }
}
