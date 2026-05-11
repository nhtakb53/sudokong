import { useMemo } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import type { Digit } from '../../core/types';
import { getRemainingCounts, useGame } from '../../game/store';
import { useTheme } from '../theme/ThemeProvider';

const DIGITS: Digit[] = [1, 2, 3, 4, 5, 6, 7, 8, 9];

export function DigitPad() {
  const { theme } = useTheme();
  const input = useGame((s) => s.inputDigit);
  const board = useGame((s) => s.current);
  const counts = useMemo(() => getRemainingCounts(board), [board]);

  return (
    <View style={styles.row}>
      {DIGITS.map((d) => {
        const remaining = counts[d];
        const exhausted = remaining <= 0;
        return (
          <Pressable
            key={d}
            onPress={() => input(d)}
            style={({ pressed }) => [
              styles.btn,
              {
                backgroundColor: pressed ? theme.buttonBgActive : theme.buttonBg,
                borderColor: theme.border,
                opacity: exhausted ? 0.5 : 1,
              },
            ]}
          >
            <Text style={[styles.digit, { color: theme.text }]}>{d}</Text>
            <Text style={[styles.count, { color: theme.textMuted }]}>
              {remaining}
            </Text>
          </Pressable>
        );
      })}
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
  digit: { fontSize: 22, fontWeight: '500', lineHeight: 26 },
  count: { fontSize: 10, marginTop: 2 },
});
