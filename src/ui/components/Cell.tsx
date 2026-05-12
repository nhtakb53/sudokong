import { useRef } from 'react';
import { Platform, Pressable, StyleSheet, Text, View } from 'react-native';
import type { Digit } from '../../core/types';
import { PEERS } from '../../core/units';
import { useGame } from '../../game/store';
import type { FontScale } from '../../game/store';
import { useTheme } from '../theme/ThemeProvider';

type Props = { r: number; c: number; size: number };

const FONT_MULT: Record<FontScale, number> = { sm: 0.88, md: 1, lg: 1.12 };

const DOUBLE_TAP_MS = 280;

export function Cell({ r, c, size }: Props) {
  const { theme } = useTheme();
  const value = useGame((s) => s.current[r][c]);
  const given = useGame((s) => s.initial[r][c] !== 0);
  const pencilMask = useGame((s) => s.pencils[r][c]);
  const selected = useGame((s) => s.selectedCell);
  const select = useGame((s) => s.select);
  const board = useGame((s) => s.current);
  const lockedDigit = useGame((s) => s.lockedDigit);
  const setLockedDigit = useGame((s) => s.setLockedDigit);
  const settings = useGame((s) => s.settings);
  const validateActive = useGame((s) => s.validateActive);
  const isInvalid = useGame((s) =>
    s.validateActive && s.invalidCells.includes(`${r},${c}`),
  );
  const hasConflict = useGame((s) => {
    const v = s.current[r][c];
    if (v === 0) return false;
    for (const [pr, pc] of PEERS[r][c]) {
      if (s.current[pr][pc] === v) return true;
    }
    return false;
  });

  const isSelected = selected?.r === r && selected?.c === c;
  const sameRow = !!selected && selected.r === r;
  const sameCol = !!selected && selected.c === c;
  const sameBox =
    !!selected &&
    Math.floor(selected.r / 3) === Math.floor(r / 3) &&
    Math.floor(selected.c / 3) === Math.floor(c / 3);
  const isPeer = (sameRow || sameCol || sameBox) && !isSelected;
  const refDigit = lockedDigit ?? (selected ? board[selected.r][selected.c] : 0);
  const isSameDigit = refDigit !== 0 && value === refDigit && !isSelected;

  let bg = theme.cellBg;
  if (given) bg = theme.cellBgGiven;
  if (settings.highlightPeers && isPeer) bg = theme.cellBgPeer;
  if (settings.highlightSameDigit && isSameDigit) bg = theme.cellBgSameDigit;
  if (validateActive && isInvalid) bg = theme.cellBgInvalid;
  if (isSelected) bg = theme.cellBgSelected;

  const borderRightWidth = c === 8 ? 0 : c % 3 === 2 ? 2 : 1;
  const borderBottomWidth = r === 8 ? 0 : r % 3 === 2 ? 2 : 1;
  const borderRightColor = c % 3 === 2 ? theme.gridLineBox : theme.gridLine;
  const borderBottomColor = r % 3 === 2 ? theme.gridLineBox : theme.gridLine;

  const mult = FONT_MULT[settings.fontScale];
  const fontSize = Math.floor(size * 0.55 * mult);
  const pencilFontSize = Math.max(11, Math.floor(size * 0.30 * mult));

  const lastTapRef = useRef(0);
  const toggleLock = () => {
    if (value === 0) return;
    setLockedDigit(lockedDigit === value ? null : (value as Digit));
  };
  const handlePress = (e: { target: unknown }) => {
    const wasSelected = isSelected;
    select(r, c);
    if (Platform.OS === 'web') {
      const tgt = e.target as { blur?: () => void } | null;
      tgt?.blur?.();
    }
    const now = Date.now();
    // Only treat as a double-tap when the second tap lands on the same cell
    // that was already selected. Prevents fast moves between cells from
    // accidentally toggling lockedDigit.
    if (wasSelected && now - lastTapRef.current < DOUBLE_TAP_MS) {
      toggleLock();
      lastTapRef.current = 0;
    } else {
      lastTapRef.current = now;
    }
  };

  const textColor =
    isInvalid && validateActive
      ? theme.textConflict
      : hasConflict
        ? theme.textConflict
        : given
          ? theme.textGiven
          : theme.textInput;

  return (
    <Pressable
      onPress={handlePress}
      onLongPress={toggleLock}
      delayLongPress={350}
      focusable={false}
      style={[
        {
          width: size,
          height: size,
          backgroundColor: bg,
          borderRightWidth,
          borderBottomWidth,
          borderRightColor,
          borderBottomColor,
          alignItems: 'center',
          justifyContent: 'center',
        },
        Platform.OS === 'web'
          ? ({
              outlineStyle: 'none',
              outlineWidth: 0,
              cursor: 'pointer',
            } as object)
          : null,
      ]}
    >
      {value !== 0 ? (
        <Text
          style={{
            fontSize,
            color: textColor,
            fontWeight: given ? '600' : '400',
          }}
        >
          {value}
        </Text>
      ) : pencilMask !== 0 ? (
        <PencilGrid
          mask={pencilMask}
          fontSize={pencilFontSize}
          color={theme.textPencil}
          highlightDigit={settings.highlightSameDigit ? refDigit : 0}
          highlightColor={theme.accent}
        />
      ) : null}
      {isSelected && (
        <View
          pointerEvents="none"
          style={{
            position: 'absolute',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            borderWidth: 2,
            borderColor: theme.accent,
          }}
        />
      )}
    </Pressable>
  );
}

function PencilGrid({
  mask,
  fontSize,
  color,
  highlightDigit,
  highlightColor,
}: {
  mask: number;
  fontSize: number;
  color: string;
  highlightDigit: number;
  highlightColor: string;
}) {
  return (
    <View style={styles.pencilGrid}>
      {Array.from({ length: 3 }, (_, gr) => (
        <View key={gr} style={styles.pencilRow}>
          {Array.from({ length: 3 }, (_, gc) => {
            const d = gr * 3 + gc + 1;
            const has = (mask & (1 << (d - 1))) !== 0;
            const hi = has && d === highlightDigit;
            return (
              <View key={gc} style={styles.pencilCell}>
                {has ? (
                  <Text
                    style={{
                      fontSize,
                      color: hi ? highlightColor : color,
                      fontWeight: hi ? '700' : '400',
                    }}
                  >
                    {d}
                  </Text>
                ) : null}
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
