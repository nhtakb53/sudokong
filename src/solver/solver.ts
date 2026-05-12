import type { Board, CandidateMask, Step } from '../core/types';
import { cloneBoard, isComplete } from '../core/board';
import { computeAllCandidates } from '../core/candidates';
import { PEERS } from '../core/units';
import { backtrackSolve } from './backtrack';
import { TECHNIQUES } from './registry';

export function nextStep(
  board: Board,
  candidates?: CandidateMask[][],
): Step | null {
  const cands = candidates ?? computeAllCandidates(board);
  for (const t of TECHNIQUES) {
    const step = t.find({ board, candidates: cands });
    if (step) return step;
  }
  return null;
}

// Apply a step in place. If `candidates` is provided, eliminations and the
// implicit clears for placements (peer cells lose the placed digit) are
// applied to it as well — important for solver loops, otherwise an
// elimination-only step (X-Wing, locked candidates, ...) loops forever
// because board never changes.
export function applyStep(
  board: Board,
  step: Step,
  candidates?: CandidateMask[][],
): Board {
  for (const p of step.placements) {
    board[p.r][p.c] = p.digit;
    if (candidates) {
      candidates[p.r][p.c] = 0;
      const mask = ~(1 << (p.digit - 1));
      for (const [pr, pc] of PEERS[p.r][p.c]) {
        candidates[pr][pc] &= mask;
      }
    }
  }
  if (candidates) {
    for (const e of step.eliminations) {
      candidates[e.r][e.c] &= ~(1 << (e.digit - 1));
    }
  }
  return board;
}

export type SolveResult = {
  steps: Step[];
  final: Board;
  usedBacktrack: boolean;
};

export function logicalSolve(initial: Board): SolveResult {
  const board = cloneBoard(initial);
  const candidates = computeAllCandidates(board);
  const steps: Step[] = [];
  while (true) {
    const step = nextStep(board, candidates);
    if (!step) break;
    // Defensive: if a step does nothing it would loop forever.
    if (step.placements.length === 0 && step.eliminations.length === 0) break;
    applyStep(board, step, candidates);
    steps.push(step);
  }
  let usedBacktrack = false;
  if (!isComplete(board)) {
    usedBacktrack = true;
    backtrackSolve(board);
  }
  return { steps, final: board, usedBacktrack };
}
