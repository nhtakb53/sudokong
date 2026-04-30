import { useTranslation } from 'react-i18next';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { useGame } from '../../game/store';
import { useTheme } from '../theme/ThemeProvider';

export function Toolbar() {
  const { theme, toggle: toggleTheme } = useTheme();
  const { t, i18n } = useTranslation();
  const mode = useGame((s) => s.mode);
  const toggleMode = useGame((s) => s.toggleMode);
  const erase = useGame((s) => s.erase);
  const undo = useGame((s) => s.undo);
  const redo = useGame((s) => s.redo);
  const newGame = useGame((s) => s.newGame);

  const buttons = [
    {
      key: 'mode',
      label: mode === 'value' ? t('play.modes.value') : t('play.modes.pencil'),
      onPress: toggleMode,
      active: mode === 'pencil',
    },
    { key: 'erase', label: t('play.actions.erase'), onPress: erase },
    { key: 'undo', label: t('play.actions.undo'), onPress: undo },
    { key: 'redo', label: t('play.actions.redo'), onPress: redo },
    { key: 'new', label: t('play.actions.new'), onPress: () => newGame() },
    { key: 'theme', label: t('play.actions.theme'), onPress: toggleTheme },
    {
      key: 'lang',
      label: t('play.actions.lang'),
      onPress: () =>
        void i18n.changeLanguage(i18n.language === 'ko' ? 'en' : 'ko'),
    },
  ];

  return (
    <View style={styles.row}>
      {buttons.map((b) => (
        <Pressable
          key={b.key}
          onPress={b.onPress}
          style={({ pressed }) => [
            styles.btn,
            {
              backgroundColor: b.active
                ? theme.buttonBgActive
                : pressed
                  ? theme.buttonBgActive
                  : theme.buttonBg,
              borderColor: theme.border,
            },
          ]}
        >
          <Text style={[styles.label, { color: theme.text }]}>{b.label}</Text>
        </Pressable>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: 'row', flexWrap: 'wrap', gap: 6 },
  btn: {
    paddingVertical: 8,
    paddingHorizontal: 12,
    borderRadius: 8,
    borderWidth: 1,
  },
  label: { fontSize: 14 },
});
