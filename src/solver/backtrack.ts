import type { Board } from '../core/types';
import { isValidPlacement } from '../core/board';

type EmptyPick = { r: number; c: number; candidates: number[] };

function findEmptyMRV(board: Board): EmptyPick | null {
  let best: EmptyPick | null = null;
  let minCount = 10;
  for (let r = 0; r < 9; r++) {
    for (let c = 0; c < 9; c++) {
      if (board[r][c] !== 0) continue;
      const cands: number[] = [];
      for (let n = 1; n <= 9; n++) {
        if (isValidPlacement(board, r, c, n)) cands.push(n);
      }
      if (cands.length < minCount) {
        minCount = cands.length;
        best = { r, c, candidates: cands };
        if (cands.length <= 1) return best;
      }
    }
  }
  return best;
}

export function backtrackSolve(board: Board): boolean {
  const find = findEmptyMRV(board);
  if (!find) return true;
  const { r, c, candidates } = find;
  if (candidates.length === 0) return false;
  for (const d of candidates) {
    board[r][c] = d;
    if (backtrackSolve(board)) return true;
    board[r][c] = 0;
  }
  return false;
}

// Counts solutions up to `limit`. Mutates `board` during search but restores it.
export function countSolutions(board: Board, limit = 2): number {
  let count = 0;
  function search(): boolean {
    const find = findEmptyMRV(board);
    if (!find) {
      count++;
      return count >= limit;
    }
    const { r, c, candidates } = find;
    for (const d of candidates) {
      board[r][c] = d;
      if (search()) return true;
      board[r][c] = 0;
    }
    return false;
  }
  search();
  return count;
}
