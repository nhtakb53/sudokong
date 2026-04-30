import type { Digit, Elimination, Step } from '../../core/types';
import { hasCandidate } from '../../core/candidates';
import { BOXES } from '../../core/units';
import { boxIndex } from '../../core/board';
import type { SolverContext, Technique } from '../Technique';

// Claiming (Box/Line Reduction): in a row (or column), all candidate cells for D
// fall inside a single box. Therefore D is eliminated from the rest of that box.
export const lockedCandidatesClaiming: Technique = {
  id: 'locked_candidates_claiming',
  level: 1,
  find({ board, candidates }: SolverContext): Step | null {
    // Scan rows
    for (let r = 0; r < 9; r++) {
      const step = scanLine(board, candidates, 'row', r);
      if (step) return step;
    }
    // Scan columns
    for (let c = 0; c < 9; c++) {
      const step = scanLine(board, candidates, 'col', c);
      if (step) return step;
    }
    return null;
  },
};

function scanLine(
  board: number[][],
  candidates: number[][],
  line: 'row' | 'col',
  i: number,
): Step | null {
  for (let d = 1; d <= 9; d++) {
    const digit = d as Digit;
    const positions: Array<[number, number]> = [];
    let placedAlready = false;
    for (let j = 0; j < 9; j++) {
      const r = line === 'row' ? i : j;
      const c = line === 'row' ? j : i;
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
    const firstBox = boxIndex(positions[0][0], positions[0][1]);
    if (!positions.every(([pr, pc]) => boxIndex(pr, pc) === firstBox)) continue;

    const eliminations: Elimination[] = [];
    for (const [br, bc] of BOXES[firstBox]) {
      if (line === 'row' && br === i) continue;
      if (line === 'col' && bc === i) continue;
      if (board[br][bc] !== 0) continue;
      if (hasCandidate(candidates[br][bc], digit)) {
        eliminations.push({ r: br, c: bc, digit });
      }
    }
    if (eliminations.length === 0) continue;

    return {
      technique: 'locked_candidates_claiming',
      placements: [],
      eliminations,
      highlights: {
        cells: positions.map(([r, c]) => ({ r, c, role: 'base' })),
        candidates: positions.map(([r, c]) => ({ r, c, digit, role: 'strong' })),
        units: [
          { kind: line, index: i, role: 'base' },
          { kind: 'box', index: firstBox, role: 'cover' },
        ],
      },
      explanationKey: 'techniques.locked_candidates_claiming.step',
      explanationParams: { digit, line, lineIndex: i + 1, box: firstBox + 1 },
    };
  }
  return null;
}
