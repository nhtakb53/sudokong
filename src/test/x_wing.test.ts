import { describe, expect, it } from 'vitest';
import { emptyBoard } from '../core/board';
import type { Board, CandidateMask } from '../core/types';
import { xWing } from '../solver/techniques/xWing';

function makeFullCandidates(): CandidateMask[][] {
  return Array.from({ length: 9 }, () => Array(9).fill(0x1ff));
}

function dropDigitFromCell(
  cands: CandidateMask[][],
  r: number,
  c: number,
  digit: number,
) {
  cands[r][c] &= ~(1 << (digit - 1));
}

describe('xWing technique', () => {
  it('detects a row-based X-Wing on digit 5 at rows 0 and 4, cols 0 and 5', () => {
    const board: Board = emptyBoard();
    const cands = makeFullCandidates();
    // Restrict digit 5 in row 0 to cols 0 and 5
    for (let c = 0; c < 9; c++) {
      if (c !== 0 && c !== 5) dropDigitFromCell(cands, 0, c, 5);
    }
    // Same for row 4
    for (let c = 0; c < 9; c++) {
      if (c !== 0 && c !== 5) dropDigitFromCell(cands, 4, c, 5);
    }
    // At least one other row keeps digit 5 in col 0 or 5 — leave defaults (0x1ff).

    const step = xWing.find({ board, candidates: cands });
    expect(step).not.toBeNull();
    expect(step!.technique).toBe('x_wing');
    expect(step!.placements).toEqual([]);
    expect(step!.eliminations.length).toBeGreaterThan(0);
    // All eliminations should be in cols 0 or 5, in rows other than 0 or 4
    for (const e of step!.eliminations) {
      expect(e.digit).toBe(5);
      expect([0, 5].includes(e.c)).toBe(true);
      expect([0, 4].includes(e.r)).toBe(false);
    }
    // The four corners are all base cells
    const cellSet = new Set(
      step!.highlights.cells?.map((p) => `${p.r}-${p.c}`) ?? [],
    );
    expect(cellSet.has('0-0')).toBe(true);
    expect(cellSet.has('0-5')).toBe(true);
    expect(cellSet.has('4-0')).toBe(true);
    expect(cellSet.has('4-5')).toBe(true);
  });

  it('detects a column-based X-Wing on digit 3 at cols 1 and 7, rows 2 and 6', () => {
    const board: Board = emptyBoard();
    const cands = makeFullCandidates();
    for (let r = 0; r < 9; r++) {
      if (r !== 2 && r !== 6) dropDigitFromCell(cands, r, 1, 3);
    }
    for (let r = 0; r < 9; r++) {
      if (r !== 2 && r !== 6) dropDigitFromCell(cands, r, 7, 3);
    }

    const step = xWing.find({ board, candidates: cands });
    expect(step).not.toBeNull();
    expect(step!.technique).toBe('x_wing');
    expect(step!.eliminations.length).toBeGreaterThan(0);
    for (const e of step!.eliminations) {
      expect(e.digit).toBe(3);
      expect([2, 6].includes(e.r)).toBe(true);
      expect([1, 7].includes(e.c)).toBe(false);
    }
  });

  it('returns null when no X-Wing pattern exists', () => {
    const board: Board = emptyBoard();
    const cands = makeFullCandidates();
    // Default full candidates: every digit appears in every row at all 9 cols.
    // No row has a digit confined to 2 columns → no X-Wing.
    const step = xWing.find({ board, candidates: cands });
    expect(step).toBeNull();
  });
});
