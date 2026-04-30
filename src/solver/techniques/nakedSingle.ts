import type { Step } from '../../core/types';
import { maskToDigits, popcount } from '../../core/candidates';
import type { SolverContext, Technique } from '../Technique';

export const nakedSingle: Technique = {
  id: 'naked_single',
  level: 0,
  find({ board, candidates }: SolverContext): Step | null {
    for (let r = 0; r < 9; r++) {
      for (let c = 0; c < 9; c++) {
        if (board[r][c] !== 0) continue;
        const mask = candidates[r][c];
        if (popcount(mask) === 1) {
          const digit = maskToDigits(mask)[0];
          return {
            technique: 'naked_single',
            placements: [{ r, c, digit }],
            eliminations: [],
            highlights: {
              cells: [{ r, c, role: 'target' }],
              candidates: [{ r, c, digit, role: 'target' }],
            },
            explanationKey: 'techniques.naked_single.step',
            explanationParams: { row: r + 1, col: c + 1, digit },
          };
        }
      }
    }
    return null;
  },
};
