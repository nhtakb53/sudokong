export type Unit = readonly (readonly [number, number])[];

const buildRows = (): Unit[] => {
  const rows: Unit[] = [];
  for (let r = 0; r < 9; r++) {
    const u: [number, number][] = [];
    for (let c = 0; c < 9; c++) u.push([r, c]);
    rows.push(u);
  }
  return rows;
};

const buildCols = (): Unit[] => {
  const cols: Unit[] = [];
  for (let c = 0; c < 9; c++) {
    const u: [number, number][] = [];
    for (let r = 0; r < 9; r++) u.push([r, c]);
    cols.push(u);
  }
  return cols;
};

const buildBoxes = (): Unit[] => {
  const boxes: Unit[] = [];
  for (let br = 0; br < 3; br++) {
    for (let bc = 0; bc < 3; bc++) {
      const u: [number, number][] = [];
      for (let dr = 0; dr < 3; dr++) {
        for (let dc = 0; dc < 3; dc++) u.push([br * 3 + dr, bc * 3 + dc]);
      }
      boxes.push(u);
    }
  }
  return boxes;
};

export const ROWS: Unit[] = buildRows();
export const COLS: Unit[] = buildCols();
export const BOXES: Unit[] = buildBoxes();
export const ALL_UNITS: Unit[] = [...ROWS, ...COLS, ...BOXES];

// PEERS[r][c] = the 20 cells sharing a row/col/box with (r,c).
export const PEERS: ReadonlyArray<
  ReadonlyArray<readonly (readonly [number, number])[]>
> = (() => {
  const out: [number, number][][][] = Array.from({ length: 9 }, () =>
    Array.from({ length: 9 }, () => [] as [number, number][]),
  );
  for (let r = 0; r < 9; r++) {
    for (let c = 0; c < 9; c++) {
      const seen = new Set<string>();
      const add = (pr: number, pc: number) => {
        if (pr === r && pc === c) return;
        const k = `${pr},${pc}`;
        if (seen.has(k)) return;
        seen.add(k);
        out[r][c].push([pr, pc]);
      };
      for (let i = 0; i < 9; i++) add(r, i);
      for (let i = 0; i < 9; i++) add(i, c);
      const br = Math.floor(r / 3) * 3;
      const bc = Math.floor(c / 3) * 3;
      for (let i = 0; i < 3; i++) {
        for (let j = 0; j < 3; j++) add(br + i, bc + j);
      }
    }
  }
  return out;
})();
