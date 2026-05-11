import { StyleSheet, Text, View } from 'react-native';
import { computeAllCandidates } from '../../core/candidates';
import type { Board, Highlight, Step } from '../../core/types';
import { useTheme } from '../theme/ThemeProvider';
import { StepOverlay } from './StepOverlay';

type Props = {
  board: Board;
  step: Step;
  highlights: Highlight;
  showEliminations: boolean;
  showPlacements: boolean;
  size: number;
};

export function LessonBoard({
  board,
  step,
  highlights,
  showEliminations,
  showPlacements,
  size,
}: Props) {
  const { theme } = useTheme();
  const cellSize = Math.floor((size - 4) / 9);
  const innerSize = cellSize * 9;
  const candidates = computeAllCandidates(board);

  const filtered: Step = {
    ...step,
    highlights,
    eliminations: showEliminations ? step.eliminations : [],
    placements: showPlacements ? step.placements : [],
  };

  return (
    <View style={{ padding: 2, backgroundColor: theme.gridLineBox }}>
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
              <StaticCell
                key={c}
                r={r}
                c={c}
                value={board[r][c]}
                pencilMask={candidates[r][c]}
                size={cellSize}
              />
            ))}
          </View>
        ))}
        <StepOverlay step={filtered} cellSize={cellSize} />
      </View>
    </View>
  );
}

function StaticCell({
  r,
  c,
  value,
  pencilMask,
  size,
}: {
  r: number;
  c: number;
  value: number;
  pencilMask: number;
  size: number;
}) {
  const { theme } = useTheme();
  const given = value !== 0;
  const borderRightWidth = c === 8 ? 0 : c % 3 === 2 ? 2 : 1;
  const borderBottomWidth = r === 8 ? 0 : r % 3 === 2 ? 2 : 1;
  const borderRightColor = c % 3 === 2 ? theme.gridLineBox : theme.gridLine;
  const borderBottomColor = r % 3 === 2 ? theme.gridLineBox : theme.gridLine;
  const fontSize = Math.floor(size * 0.55);
  const pencilFontSize = Math.max(8, Math.floor(size * 0.28));

  return (
    <View
      style={{
        width: size,
        height: size,
        backgroundColor: given ? theme.cellBgGiven : theme.cellBg,
        borderRightWidth,
        borderBottomWidth,
        borderRightColor,
        borderBottomColor,
        alignItems: 'center',
        justifyContent: 'center',
      }}
    >
      {value !== 0 ? (
        <Text style={{ fontSize, color: theme.textGiven, fontWeight: '600' }}>
          {value}
        </Text>
      ) : pencilMask !== 0 ? (
        <PencilGrid
          mask={pencilMask}
          fontSize={pencilFontSize}
          color={theme.textPencil}
        />
      ) : null}
    </View>
  );
}

function PencilGrid({
  mask,
  fontSize,
  color,
}: {
  mask: number;
  fontSize: number;
  color: string;
}) {
  return (
    <View style={styles.pencilGrid}>
      {Array.from({ length: 3 }, (_, gr) => (
        <View key={gr} style={styles.pencilRow}>
          {Array.from({ length: 3 }, (_, gc) => {
            const d = gr * 3 + gc + 1;
            const has = (mask & (1 << (d - 1))) !== 0;
            return (
              <View key={gc} style={styles.pencilCell}>
                {has ? <Text style={{ fontSize, color }}>{d}</Text> : null}
              </View>
            );
          })}
        </View>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  pencilGrid: { flex: 1, alignSelf: 'stretch', padding: 2 },
  pencilRow: { flex: 1, flexDirection: 'row' },
  pencilCell: { flex: 1, alignItems: 'center', justifyContent: 'center' },
});
