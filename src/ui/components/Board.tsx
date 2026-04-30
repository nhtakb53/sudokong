import { View } from 'react-native';
import { useTheme } from '../theme/ThemeProvider';
import { Cell } from './Cell';

export function Board({ size }: { size: number }) {
  const { theme } = useTheme();
  const cellSize = Math.floor(size / 9);
  const boardSize = cellSize * 9;
  return (
    <View
      style={{
        width: boardSize,
        height: boardSize,
        backgroundColor: theme.bg,
        borderWidth: 2,
        borderColor: theme.gridLineBox,
      }}
    >
      {Array.from({ length: 9 }, (_, r) => (
        <View key={r} style={{ flexDirection: 'row' }}>
          {Array.from({ length: 9 }, (_, c) => (
            <Cell key={c} r={r} c={c} size={cellSize} />
          ))}
        </View>
      ))}
    </View>
  );
}
