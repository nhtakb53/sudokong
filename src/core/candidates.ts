import type { Board, CandidateMask, Digit } from './types';
import { PEERS } from './units';

export const ALL_DIGITS_MASK: CandidateMask = 0x1ff; // bits 0..8 set

export const digitMask = (d: Digit): CandidateMask => 1 << (d - 1);

export const hasCandidate = (mask: CandidateMask, d: Digit): boolean =>
  (mask & digitMask(d)) !== 0;

export const addCandidate = (mask: CandidateMask, d: Digit): CandidateMask =>
  mask | digitMask(d);

export const removeCandidate = (mask: CandidateMask, d: Digit): CandidateMask =>
  mask & ~digitMask(d);

export function popcount(mask: CandidateMask): number {
  let n = mask;
  n = n - ((n >> 1) & 0x55555555);
  n = (n & 0x33333333) + ((n >> 2) & 0x33333333);
  return (((n + (n >> 4)) & 0x0f0f0f0f) * 0x01010101) >> 24;
}

export function maskToDigits(mask: CandidateMask): Digit[] {
  const out: Digit[] = [];
  for (let i = 0; i < 9; i++) {
    if (mask & (1 << i)) out.push((i + 1) as Digit);
  }
  return out;
}

export function computeAllCandidates(board: Board): CandidateMask[][] {
  const cands: CandidateMask[][] = Array.from({ length: 9 }, () =>
    Array(9).fill(0),
  );
  for (let r = 0; r < 9; r++) {
    for (let c = 0; c < 9; c++) {
      if (board[r][c] !== 0) {
        cands[r][c] = 0;
        continue;
      }
      let mask = ALL_DIGITS_MASK;
      for (const [pr, pc] of PEERS[r][c]) {
        const v = board[pr][pc];
        if (v !== 0) mask &= ~digitMask(v as Digit);
      }
      cands[r][c] = mask;
    }
  }
  return cands;
}
