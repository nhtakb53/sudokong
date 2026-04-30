import { Pressable, StyleSheet, Text, View } from 'react-native';
import type { Digit } from '../../core/types';
import { useGame } from '../../game/store';
import { useTheme } from '../theme/ThemeProvider';

const DIGITS: Digit[] = [1, 2, 3, 4, 5, 6, 7, 8, 9];

export function DigitPad() {
  const { theme } = useTheme();
  const input = useGame((s) => s.inputDigit);
  return (
    <View style={styles.row}>
      {DIGITS.map((d) => (
        <Pressable
          key={d}
          onPress={() => input(d)}
          style={({ pressed }) => [
            styles.btn,
            {
              backgroundColor: pressed ? theme.buttonBgActive : theme.buttonBg,
              borderColor: theme.border,
            },
          ]}
        >
          <Text style={[styles.digit, { color: theme.text }]}>{d}</Text>
        </Pressable>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: 'row', gap: 4 },
  btn: {
    flex: 1,
    aspectRatio: 1,
    borderRadius: 8,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  digit: { fontSize: 24, fontWeight: '500' },
});
