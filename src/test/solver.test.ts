import { describe, expect, it } from 'vitest';
import {
  hasConflicts,
  isComplete,
  parseBoard,
  serializeBoard,
} from '../core/board';
import { backtrackSolve, countSolutions } from '../solver/backtrack';
import { logicalSolve, nextStep } from '../solver/solver';
import { checkUniqueness } from '../solver/uniqueness';
import { PUZZLES } from './fixtures';

describe('parse/serialize', () => {
  it('roundtrips an 81-char string', () => {
    const b = parseBoard(PUZZLES.EASY);
    expect(serializeBoard(b)).toBe(PUZZLES.EASY);
  });

  it('rejects malformed strings', () => {
    expect(() => parseBoard('123')).toThrow();
    expect(() => parseBoard('a'.repeat(81))).toThrow();
  });
});

describe('backtrackSolve', () => {
  it('solves EASY to its known solution', () => {
    const b = parseBoard(PUZZLES.EASY);
    expect(backtrackSolve(b)).toBe(true);
    expect(isComplete(b)).toBe(true);
    expect(hasConflicts(b)).toBe(false);
    expect(serializeBoard(b)).toBe(PUZZLES.EASY_SOLUTION);
  });

  it('solves MEDIUM and HARD', () => {
    for (const key of ['MEDIUM', 'HARD'] as const) {
      const b = parseBoard(PUZZLES[key]);
      expect(backtrackSolve(b)).toBe(true);
      expect(isComplete(b)).toBe(true);
      expect(hasConflicts(b)).toBe(false);
    }
  });
});

describe('countSolutions', () => {
  it('reports unique solution for EASY', () => {
    const b = parseBoard(PUZZLES.EASY);
    expect(countSolutions(b, 2)).toBe(1);
  });
});

describe('checkUniqueness', () => {
  it('accepts EASY as unique', () => {
    expect(checkUniqueness(parseBoard(PUZZLES.EASY))).toEqual({
      kind: 'unique',
    });
  });

  it('rejects empty board (too few clues)', () => {
    expect(checkUniqueness(parseBoard('.'.repeat(81)))).toEqual({
      kind: 'invalid',
      reason: 'too_few_clues',
    });
  });
});

describe('logicalSolve / nextStep', () => {
  it('first step on EASY is a single', () => {
    const step = nextStep(parseBoard(PUZZLES.EASY));
    expect(step).not.toBeNull();
    expect(['naked_single', 'hidden_single']).toContain(step!.technique);
    expect(step!.placements).toHaveLength(1);
  });

  it('logicalSolve fully solves EASY using techniques only', () => {
    const result = logicalSolve(parseBoard(PUZZLES.EASY));
    expect(isComplete(result.final)).toBe(true);
    expect(serializeBoard(result.final)).toBe(PUZZLES.EASY_SOLUTION);
    expect(result.steps.length).toBeGreaterThan(0);
    expect(result.usedBacktrack).toBe(false);
  });

  it('logicalSolve completes HARD (likely with backtrack fallback)', () => {
    const result = logicalSolve(parseBoard(PUZZLES.HARD));
    expect(isComplete(result.final)).toBe(true);
    expect(hasConflicts(result.final)).toBe(false);
  });
});
