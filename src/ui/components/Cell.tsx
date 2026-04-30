import { Pressable, StyleSheet, Text, View } from 'react-native';
import { useGame } from '../../game/store';
import { useTheme } from '../theme/ThemeProvider';

type Props = { r: number; c: number; size: number };

export function Cell({ r, c, size }: Props) {
  const { theme } = useTheme();
  const value = useGame((s) => s.current[r][c]);
  const given = useGame((s) => s.initial[r][c] !== 0);
  const pencilMask = useGame((s) => s.pencils[r][c]);
  const selected = useGame((s) => s.selectedCell);
  const select = useGame((s) => s.select);
  const board = useGame((s) => s.current);

  const isSelected = selected?.r === r && selected?.c === c;
  const sameRow = !!selected && selected.r === r;
  const sameCol = !!selected && selected.c === c;
  const sameBox =
    !!selected &&
    Math.floor(selected.r / 3) === Math.floor(r / 3) &&
    Math.floor(selected.c / 3) === Math.floor(c / 3);
  const isPeer = (sameRow || sameCol || sameBox) && !isSelected;
  const selectedValue = selected ? board[selected.r][selected.c] : 0;
  const isSameDigit =
    selectedValue !== 0 && value === selectedValue && !isSelected;

  let bg = theme.cellBg;
  if (given) bg = theme.cellBgGiven;
  if (isPeer) bg = theme.cellBgPeer;
  if (isSameDigit) bg = theme.cellBgSameDigit;
  if (isSelected) bg = theme.cellBgSelected;

  const borderRightWidth = c === 8 ? 0 : c % 3 === 2 ? 2 : 1;
  const borderBottomWidth = r === 8 ? 0 : r % 3 === 2 ? 2 : 1;
  const borderRightColor = c % 3 === 2 ? theme.gridLineBox : theme.gridLine;
  const borderBottomColor = r % 3 === 2 ? theme.gridLineBox : theme.gridLine;

  const fontSize = Math.floor(size * 0.55);
  const pencilFontSize = Math.max(8, Math.floor(size * 0.22));

  return (
    <Pressable
      onPress={() => select(r, c)}
      style={{
        width: size,
        height: size,
        backgroundColor: bg,
        borderRightWidth,
        borderBottomWidth,
        borderRightColor,
        borderBottomColor,
        alignItems: 'center',
        justifyContent: 'center',
      }}
    >
      {value !== 0 ? (
        <Text
          style={{
            fontSize,
            color: given ? theme.textGiven : theme.textInput,
            fontWeight: given ? '600' : '400',
          }}
        >
          {value}
        </Text>
      ) : pencilMask !== 0 ? (
        <PencilGrid mask={pencilMask} fontSize={pencilFontSize} color={theme.textPencil} />
      ) : null}
    </Pressable>
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
