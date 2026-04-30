import type { Digit, Elimination, Step } from '../../core/types';
import { hasCandidate } from '../../core/candidates';
import { BOXES } from '../../core/units';
import { boxIndex } from '../../core/board';
import type { SolverContext, Technique } from '../Technique';

// Pointing: in a box, all candidate cells for digit D are confined to a single row
// (or column). Therefore D is eliminated from that row/column outside the box.
export const lockedCandidatesPointing: Technique = {
  id: 'locked_candidates_pointing',
  level: 1,
  find({ board, candidates }: SolverContext): Step | null {
    for (let b = 0; b < 9; b++) {
      for (let d = 1; d <= 9; d++) {
        const digit = d as Digit;
        const positions: Array<[number, number]> = [];
        let placedAlready = false;
        for (const [r, c] of BOXES[b]) {
          if (board[r][c] === digit) {
            placedAlready = true;
            break;
          }
          if (board[r][c] === 0 && hasCandidate(candidates[r][c], digit)) {
            positions.push([r, c]);
          }
        }
        if (placedAlready) continue;
        if (positions.length < 2) continue;

        const r0 = positions[0][0];
        const c0 = positions[0][1];
        const sameRow = positions.every(([r]) => r === r0);
        const sameCol = positions.every(([, c]) => c === c0);

        if (sameRow) {
          const eliminations: Elimination[] = [];
          for (let c = 0; c < 9; c++) {
            if (boxIndex(r0, c) === b) continue;
            if (board[r0][c] !== 0) continue;
            if (hasCandidate(candidates[r0][c], digit)) {
              eliminations.push({ r: r0, c, digit });
            }
          }
          if (eliminations.length > 0) {
            return makeStep(positions, digit, b, 'row', r0, eliminations);
          }
        } else if (sameCol) {
          const eliminations: Elimination[] = [];
          for (let r = 0; r < 9; r++) {
            if (boxIndex(r, c0) === b) continue;
            if (board[r][c0] !== 0) continue;
            if (hasCandidate(candidates[r][c0], digit)) {
              eliminations.push({ r, c: c0, digit });
            }
          }
          if (eliminations.length > 0) {
            return makeStep(positions, digit, b, 'col', c0, eliminations);
          }
        }
      }
    }
    return null;
  },
};

function makeStep(
  positions: Array<[number, number]>,
  digit: Digit,
  box: number,
  line: 'row' | 'col',
  lineIndex: number,
  eliminations: Elimination[],
): Step {
  return {
    technique: 'locked_candidates_pointing',
    placements: [],
    eliminations,
    highlights: {
      cells: positions.map(([r, c]) => ({ r, c, role: 'base' })),
      candidates: positions.map(([r, c]) => ({ r, c, digit, role: 'strong' })),
      units: [
        { kind: 'box', index: box, role: 'base' },
        { kind: line, index: lineIndex, role: 'cover' },
      ],
    },
    explanationKey: 'techniques.locked_candidates_pointing.step',
    explanationParams: { digit, box: box + 1, line, lineIndex: lineIndex + 1 },
  };
}
