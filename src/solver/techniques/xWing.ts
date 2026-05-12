import type { Digit, Elimination, Step } from '../../core/types';
import { hasCandidate } from '../../core/candidates';
import type { SolverContext, Technique } from '../Technique';

type Pair = [number, number];

function findRowBased(
  d: Digit,
  candidates: number[][],
): {
  rowsWithTwo: { row: number; cols: Pair }[];
} {
  const rowsWithTwo: { row: number; cols: Pair }[] = [];
  for (let r = 0; r < 9; r++) {
    const cols: number[] = [];
    for (let c = 0; c < 9; c++) {
      if (hasCandidate(candidates[r][c], d)) cols.push(c);
    }
    if (cols.length === 2) {
      rowsWithTwo.push({ row: r, cols: [cols[0], cols[1]] });
    }
  }
  return { rowsWithTwo };
}

function findColBased(
  d: Digit,
  candidates: number[][],
): {
  colsWithTwo: { col: number; rows: Pair }[];
} {
  const colsWithTwo: { col: number; rows: Pair }[] = [];
  for (let c = 0; c < 9; c++) {
    const rows: number[] = [];
    for (let r = 0; r < 9; r++) {
      if (hasCandidate(candidates[r][c], d)) rows.push(r);
    }
    if (rows.length === 2) {
      colsWithTwo.push({ col: c, rows: [rows[0], rows[1]] });
    }
  }
  return { colsWithTwo };
}

export const xWing: Technique = {
  id: 'x_wing',
  level: 3,
  find({ candidates }: SolverContext): Step | null {
    for (let n = 1; n <= 9; n++) {
      const d = n as Digit;

      // Row-based: two rows whose only `d`-candidates sit in the same two cols
      const { rowsWithTwo } = findRowBased(d, candidates);
      for (let i = 0; i < rowsWithTwo.length; i++) {
        for (let j = i + 1; j < rowsWithTwo.length; j++) {
          const a = rowsWithTwo[i];
          const b = rowsWithTwo[j];
          if (a.cols[0] !== b.cols[0] || a.cols[1] !== b.cols[1]) continue;
          const elim: Elimination[] = [];
          for (const c of a.cols) {
            for (let r = 0; r < 9; r++) {
              if (r === a.row || r === b.row) continue;
              if (hasCandidate(candidates[r][c], d)) elim.push({ r, c, digit: d });
            }
          }
          if (elim.length === 0) continue;
          const corners = [
            { r: a.row, c: a.cols[0] },
            { r: a.row, c: a.cols[1] },
            { r: b.row, c: a.cols[0] },
            { r: b.row, c: a.cols[1] },
          ];
          return {
            technique: 'x_wing',
            placements: [],
            eliminations: elim,
            highlights: {
              cells: corners.map((p) => ({ ...p, role: 'base' as const })),
              candidates: corners.map((p) => ({
                ...p,
                digit: d,
                role: 'strong' as const,
              })),
              units: [
                { kind: 'row', index: a.row, role: 'base' },
                { kind: 'row', index: b.row, role: 'base' },
                { kind: 'col', index: a.cols[0], role: 'cover' },
                { kind: 'col', index: a.cols[1], role: 'cover' },
              ],
            },
            explanationKey: 'techniques.x_wing.step',
            explanationParams: {
              digit: d,
              orient: 'row',
              base1: a.row + 1,
              base2: b.row + 1,
              cover1: a.cols[0] + 1,
              cover2: a.cols[1] + 1,
            },
          };
        }
      }

      // Column-based: two cols whose only `d`-candidates sit in the same two rows
      const { colsWithTwo } = findColBased(d, candidates);
      for (let i = 0; i < colsWithTwo.length; i++) {
        for (let j = i + 1; j < colsWithTwo.length; j++) {
          const a = colsWithTwo[i];
          const b = colsWithTwo[j];
          if (a.rows[0] !== b.rows[0] || a.rows[1] !== b.rows[1]) continue;
          const elim: Elimination[] = [];
          for (const r of a.rows) {
            for (let c = 0; c < 9; c++) {
              if (c === a.col || c === b.col) continue;
              if (hasCandidate(candidates[r][c], d)) elim.push({ r, c, digit: d });
            }
          }
          if (elim.length === 0) continue;
          const corners = [
            { r: a.rows[0], c: a.col },
            { r: a.rows[1], c: a.col },
            { r: a.rows[0], c: b.col },
            { r: a.rows[1], c: b.col },
          ];
          return {
            technique: 'x_wing',
            placements: [],
            eliminations: elim,
            highlights: {
              cells: corners.map((p) => ({ ...p, role: 'base' as const })),
              candidates: corners.map((p) => ({
                ...p,
                digit: d,
                role: 'strong' as const,
              })),
              units: [
                { kind: 'col', index: a.col, role: 'base' },
                { kind: 'col', index: b.col, role: 'base' },
                { kind: 'row', index: a.rows[0], role: 'cover' },
                { kind: 'row', index: a.rows[1], role: 'cover' },
              ],
            },
            explanationKey: 'techniques.x_wing.step',
            explanationParams: {
              digit: d,
              orient: 'col',
              base1: a.col + 1,
              base2: b.col + 1,
              cover1: a.rows[0] + 1,
              cover2: a.rows[1] + 1,
            },
          };
        }
      }
    }
    return null;
  },
};
