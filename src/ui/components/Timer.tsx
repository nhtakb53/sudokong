import { useEffect, useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { useGame } from '../../game/store';
import { useTheme } from '../theme/ThemeProvider';

const pad = (n: number) => (n < 10 ? `0${n}` : `${n}`);

const format = (ms: number) => {
  const total = Math.max(0, Math.floor(ms / 1000));
  const h = Math.floor(total / 3600);
  const m = Math.floor((total % 3600) / 60);
  const s = total % 60;
  return h > 0 ? `${h}:${pad(m)}:${pad(s)}` : `${pad(m)}:${pad(s)}`;
};

export function Timer() {
  const { theme } = useTheme();
  const startedAt = useGame((s) => s.startedAt);
  const completedAt = useGame((s) => s.completedAt);
  const pausedAt = useGame((s) => s.pausedAt);
  const [now, setNow] = useState(() => Date.now());

  useEffect(() => {
    if (completedAt != null || pausedAt != null) return;
    const id = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(id);
  }, [completedAt, pausedAt]);

  const elapsed = (completedAt ?? pausedAt ?? now) - startedAt;
  const done = completedAt != null;

  return (
    <View style={styles.wrap}>
      <Text
        style={[
          styles.text,
          { color: done ? theme.accent : theme.textMuted },
        ]}
      >
        {format(elapsed)}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: { alignItems: 'center' },
  text: {
    fontSize: 16,
    fontWeight: '600',
    fontVariant: ['tabular-nums'],
  },
});
