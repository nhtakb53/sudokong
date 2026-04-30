import type { Board, Step } from '../core/types';
import { cloneBoard, isComplete } from '../core/board';
import { computeAllCandidates } from '../core/candidates';
import { backtrackSolve } from './backtrack';
import { TECHNIQUES } from './registry';

export function nextStep(board: Board): Step | null {
  const candidates = computeAllCandidates(board);
  for (const t of TECHNIQUES) {
    const step = t.find({ board, candidates });
    if (step) return step;
  }
  return null;
}

export function applyStep(board: Board, step: Step): Board {
  for (const p of step.placements) board[p.r][p.c] = p.digit;
  return board;
}

export type SolveResult = {
  steps: Step[];
  final: Board;
  usedBacktrack: boolean;
};

export function logicalSolve(initial: Board): SolveResult {
  const board = cloneBoard(initial);
  const steps: Step[] = [];
  while (true) {
    const step = nextStep(board);
    if (!step) break;
    applyStep(board, step);
    steps.push(step);
  }
  let usedBacktrack = false;
  if (!isComplete(board)) {
    usedBacktrack = true;
    backtrackSolve(board);
  }
  return { steps, final: board, usedBacktrack };
}
