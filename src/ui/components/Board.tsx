import { View } from 'react-native';
import { useGame } from '../../game/store';
import { useTheme } from '../theme/ThemeProvider';
import { Cell } from './Cell';
import { StepOverlay } from './StepOverlay';

export function Board({ size }: { size: number }) {
  const { theme } = useTheme();
  const hint = useGame((s) => s.hint);
  // Reserve 4px (2px on each side) for the outer border. Cells consume the rest.
  const cellSize = Math.floor((size - 4) / 9);
  const innerSize = cellSize * 9;
  return (
    <View
      style={{
        padding: 2,
        backgroundColor: theme.gridLineBox,
      }}
    >
      <View
        style={{
          width: innerSize,
          height: innerSize,
          backgroundColor: theme.bg,
        }}
      >
        {Array.from({ length: 9 }, (_, r) => (
          <View key={r} style={{ flexDirection: 'row' }}>
            {Array.from({ length: 9 }, (_, c) => (
              <Cell key={c} r={r} c={c} size={cellSize} />
            ))}
          </View>
        ))}
        {hint ? <StepOverlay step={hint} cellSize={cellSize} /> : null}
      </View>
    </View>
  );
}
