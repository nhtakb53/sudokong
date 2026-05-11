import { StyleSheet, Text, View } from 'react-native';
import type { CellRole, Step, UnitKind, UnitRole } from '../../core/types';
import { useTheme } from '../theme/ThemeProvider';

const CELL_ROLE_BG: Record<CellRole, string> = {
  base: 'rgba(255, 215, 0, 0.22)',
  cover: 'rgba(0, 122, 255, 0.18)',
  target: 'rgba(255, 215, 0, 0.45)',
  pivot: 'rgba(255, 122, 0, 0.32)',
  pincer: 'rgba(150, 100, 255, 0.28)',
  fin: 'rgba(0, 200, 100, 0.28)',
};

const UNIT_ROLE_COLOR: Record<UnitRole, string> = {
  base: 'rgba(255, 200, 0, 0.85)',
  cover: 'rgba(0, 122, 255, 0.85)',
};

type Props = {
  step: Step;
  cellSize: number;
};

export function StepOverlay({ step, cellSize }: Props) {
  const { theme } = useTheme();
  const total = cellSize * 9;

  return (
    <View pointerEvents="none" style={[styles.root, { width: total, height: total }]}>
      {/* Cell role backgrounds */}
      {step.highlights.cells?.map((c, i) => (
        <View
          key={`cell-${i}`}
          style={{
            position: 'absolute',
            left: c.c * cellSize,
            top: c.r * cellSize,
            width: cellSize,
            height: cellSize,
            backgroundColor: CELL_ROLE_BG[c.role],
          }}
        />
      ))}

      {/* Unit outlines */}
      {step.highlights.units?.map((u, i) => (
        <UnitOutline
          key={`unit-${i}`}
          kind={u.kind}
          index={u.index}
          color={UNIT_ROLE_COLOR[u.role]}
          cellSize={cellSize}
        />
      ))}

      {/* Placements: large translucent digit preview */}
      {step.placements.map((p, i) => (
        <View
          key={`p-${i}`}
          style={{
            position: 'absolute',
            left: p.c * cellSize,
            top: p.r * cellSize,
            width: cellSize,
            height: cellSize,
            alignItems: 'center',
            justifyContent: 'center',
          }}
        >
          <Text
            style={{
              fontSize: Math.floor(cellSize * 0.55),
              fontWeight: '700',
              color: theme.accent,
              opacity: 0.85,
            }}
          >
            {p.digit}
          </Text>
        </View>
      ))}

      {/* Eliminations: red × over the pencil-grid position */}
      {step.eliminations.map((e, i) => {
        const sub = cellSize / 3;
        const pr = Math.floor((e.digit - 1) / 3);
        const pc = (e.digit - 1) % 3;
        return (
          <View
            key={`e-${i}`}
            style={{
              position: 'absolute',
              left: e.c * cellSize + pc * sub,
              top: e.r * cellSize + pr * sub,
              width: sub,
              height: sub,
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <Text
              style={{
                color: theme.textConflict,
                fontSize: Math.floor(sub * 0.9),
                fontWeight: '700',
                lineHeight: sub,
              }}
            >
              ×
            </Text>
          </View>
        );
      })}
    </View>
  );
}

function UnitOutline({
  kind,
  index,
  color,
  cellSize,
}: {
  kind: UnitKind;
  index: number;
  color: string;
  cellSize: number;
}) {
  let left = 0;
  let top = 0;
  let width = cellSize * 9;
  let height = cellSize * 9;
  if (kind === 'row') {
    top = index * cellSize;
    height = cellSize;
  } else if (kind === 'col') {
    left = index * cellSize;
    width = cellSize;
  } else {
    left = (index % 3) * 3 * cellSize;
    top = Math.floor(index / 3) * 3 * cellSize;
    width = cellSize * 3;
    height = cellSize * 3;
  }
  return (
    <View
      style={{
        position: 'absolute',
        left,
        top,
        width,
        height,
        borderColor: color,
        borderWidth: 2,
        borderRadius: 2,
      }}
    />
  );
}

const styles = StyleSheet.create({
  root: { position: 'absolute', top: 0, left: 0 },
});
