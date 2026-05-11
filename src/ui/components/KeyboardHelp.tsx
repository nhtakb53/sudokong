import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Platform, Pressable, StyleSheet, Text, View } from 'react-native';
import { useTheme } from '../theme/ThemeProvider';

const ENTRIES: Array<{ keys: string; i18nKey: string }> = [
  { keys: '↑ ↓ ← →', i18nKey: 'navigate' },
  { keys: '1 – 9', i18nKey: 'input' },
  { keys: '0 / Backspace / Delete', i18nKey: 'erase' },
  { keys: 'Space / P', i18nKey: 'toggle_mode' },
  { keys: '⌘Z / Ctrl+Z', i18nKey: 'undo' },
  { keys: '⌘⇧Z / Ctrl+Y', i18nKey: 'redo' },
  { keys: 'H', i18nKey: 'hint' },
  { keys: 'V', i18nKey: 'validate' },
  { keys: 'Esc', i18nKey: 'dismiss_hint' },
];

export function KeyboardHelp() {
  const { theme } = useTheme();
  const { t } = useTranslation();
  const [open, setOpen] = useState(false);

  if (Platform.OS !== 'web') return null;

  return (
    <View style={{ gap: 6 }}>
      <Pressable
        onPress={() => setOpen((v) => !v)}
        style={({ pressed }) => [
          styles.toggleBtn,
          {
            backgroundColor:
              open || pressed ? theme.buttonBgActive : theme.buttonBg,
            borderColor: theme.border,
          },
        ]}
      >
        <Text style={[styles.toggleLabel, { color: theme.text }]}>
          {open ? t('keyboard.hide') : t('keyboard.show')}
        </Text>
      </Pressable>

      {open && (
        <View
          style={[
            styles.panel,
            {
              backgroundColor: theme.bgElevated,
              borderColor: theme.border,
            },
          ]}
        >
          <Text style={[styles.title, { color: theme.text }]}>
            {t('keyboard.title')}
          </Text>
          <View style={styles.list}>
            {ENTRIES.map((e) => (
              <View key={e.i18nKey} style={styles.row}>
                <Text
                  style={[
                    styles.kbd,
                    {
                      color: theme.text,
                      backgroundColor: theme.buttonBg,
                      borderColor: theme.border,
                    },
                  ]}
                >
                  {e.keys}
                </Text>
                <Text style={[styles.desc, { color: theme.textMuted }]}>
                  {t(`keyboard.${e.i18nKey}`)}
                </Text>
              </View>
            ))}
          </View>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  toggleBtn: {
    alignSelf: 'flex-start',
    paddingVertical: 6,
    paddingHorizontal: 12,
    borderRadius: 8,
    borderWidth: 1,
  },
  toggleLabel: { fontSize: 13 },
  panel: {
    padding: 12,
    borderRadius: 10,
    borderWidth: 1,
    gap: 10,
  },
  title: { fontSize: 14, fontWeight: '600' },
  list: { gap: 6 },
  row: { flexDirection: 'row', alignItems: 'center', gap: 12, flexWrap: 'wrap' },
  kbd: {
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 4,
    borderWidth: 1,
    fontSize: 12,
    fontFamily: Platform.select({
      web: 'ui-monospace, SFMono-Regular, Menlo, monospace',
      default: 'monospace',
    }),
    minWidth: 130,
    textAlign: 'center',
  },
  desc: { fontSize: 13, flex: 1 },
});
