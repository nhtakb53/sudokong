import type { Board } from '../core/types';
import { cloneBoard, hasConflicts } from '../core/board';
import { countSolutions } from './backtrack';

export type UniquenessResult =
  | { kind: 'unique' }
  | {
      kind: 'invalid';
      reason: 'too_few_clues' | 'conflicts' | 'no_solution' | 'multiple_solutions';
    };

export function checkUniqueness(board: Board): UniquenessResult {
  const clueCount = board.flat().filter((v) => v !== 0).length;
  if (clueCount < 17) return { kind: 'invalid', reason: 'too_few_clues' };
  if (hasConflicts(board)) return { kind: 'invalid', reason: 'conflicts' };

  const copy = cloneBoard(board);
  const n = countSolutions(copy, 2);
  if (n === 0) return { kind: 'invalid', reason: 'no_solution' };
  if (n > 1) return { kind: 'invalid', reason: 'multiple_solutions' };
  return { kind: 'unique' };
}
