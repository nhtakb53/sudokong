import { useTranslation } from 'react-i18next';
import { StyleSheet, Text, useWindowDimensions, View } from 'react-native';
import { Board } from '../components/Board';
import { DigitPad } from '../components/DigitPad';
import { InputModeToggle } from '../components/InputModeToggle';
import { KeyboardHelp } from '../components/KeyboardHelp';
import { StepNarrator } from '../components/StepNarrator';
import { Timer } from '../components/Timer';
import { Toolbar } from '../components/Toolbar';
import { useKeyboardShortcuts } from '../hooks/useKeyboardShortcuts';
import { useTheme } from '../theme/ThemeProvider';

export function PlayScreen() {
  useKeyboardShortcuts();
  const { theme } = useTheme();
  const { t } = useTranslation();
  const { width } = useWindowDimensions();
  const boardSize = Math.min(width - 32, 480);

  return (
    <View style={[styles.root, { backgroundColor: theme.bg }]}>
      <View style={styles.header}>
        <Text style={[styles.title, { color: theme.text }]}>
          {t('app.title')}
        </Text>
        <Timer />
      </View>

      <View style={{ alignItems: 'center' }}>
        <Board size={boardSize} />
      </View>

      <View style={{ alignItems: 'center' }}>
        <View style={{ width: boardSize, gap: 12 }}>
          <StepNarrator />
          <Toolbar />
          <InputModeToggle />
          <DigitPad />
          <KeyboardHelp />
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, paddingHorizontal: 16, paddingTop: 48, gap: 16 },
  header: { alignItems: 'center', gap: 4 },
  title: { fontSize: 22, fontWeight: '600', textAlign: 'center' },
});
