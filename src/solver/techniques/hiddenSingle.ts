import type { Digit, Step, UnitKind } from '../../core/types';
import { hasCandidate } from '../../core/candidates';
import { BOXES, COLS, ROWS, type Unit } from '../../core/units';
import type { SolverContext, Technique } from '../Technique';

type ScanUnit = { kind: UnitKind; index: number; cells: Unit };

const UNITS: ScanUnit[] = [
  ...ROWS.map((cells, index) => ({ kind: 'row' as UnitKind, index, cells })),
  ...COLS.map((cells, index) => ({ kind: 'col' as UnitKind, index, cells })),
  ...BOXES.map((cells, index) => ({ kind: 'box' as UnitKind, index, cells })),
];

export const hiddenSingle: Technique = {
  id: 'hidden_single',
  level: 0,
  find({ board, candidates }: SolverContext): Step | null {
    for (const u of UNITS) {
      for (let d = 1; d <= 9; d++) {
        const digit = d as Digit;
        let placedAlready = false;
        const positions: Array<{ r: number; c: number }> = [];
        for (const [r, c] of u.cells) {
          if (board[r][c] === digit) {
            placedAlready = true;
            break;
          }
          if (board[r][c] === 0 && hasCandidate(candidates[r][c], digit)) {
            positions.push({ r, c });
          }
        }
        if (placedAlready) continue;
        if (positions.length === 1) {
          const { r, c } = positions[0];
          return {
            technique: 'hidden_single',
            placements: [{ r, c, digit }],
            eliminations: [],
            highlights: {
              cells: [{ r, c, role: 'target' }],
              candidates: [{ r, c, digit, role: 'target' }],
              units: [{ kind: u.kind, index: u.index, role: 'base' }],
            },
            explanationKey: 'techniques.hidden_single.step',
            explanationParams: {
              unit: u.kind,
              unitIndex: u.index + 1,
              row: r + 1,
              col: c + 1,
              digit,
            },
          };
        }
      }
    }
    return null;
  },
};
