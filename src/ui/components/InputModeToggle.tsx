import { useTranslation } from 'react-i18next';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { useGame } from '../../game/store';
import type { GameMode } from '../../game/store';
import { useTheme } from '../theme/ThemeProvider';

const MODES: GameMode[] = ['value', 'pencil'];

export function InputModeToggle() {
  const { theme } = useTheme();
  const { t } = useTranslation();
  const mode = useGame((s) => s.mode);
  const setMode = useGame((s) => s.setMode);

  return (
    <View style={[styles.row, { borderColor: theme.border }]}>
      {MODES.map((m) => {
        const active = mode === m;
        return (
          <Pressable
            key={m}
            onPress={() => setMode(m)}
            style={({ pressed }) => [
              styles.tab,
              {
                backgroundColor: active
                  ? theme.accent
                  : pressed
                    ? theme.buttonBgActive
                    : 'transparent',
              },
            ]}
          >
            <Text
              style={[
                styles.label,
                {
                  color: active ? '#ffffff' : theme.text,
                  fontWeight: active ? '600' : '500',
                  fontSize: m === 'value' ? 18 : 12,
                },
              ]}
            >
              {t(`play.modes.${m}`)}
            </Text>
          </Pressable>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    borderWidth: 1,
    borderRadius: 10,
    overflow: 'hidden',
  },
  tab: {
    flex: 1,
    paddingVertical: 10,
    alignItems: 'center',
    justifyContent: 'center',
  },
  label: {},
});
