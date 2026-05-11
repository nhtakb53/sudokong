import { describe, expect, it } from 'vitest';
import { isComplete, parseBoard, serializeBoard } from '../core/board';
import { logicalSolve } from '../solver/solver';
import { checkUniqueness } from '../solver/uniqueness';
import { PUZZLES } from '../data/samplePuzzles';

// Informational summary of solver behaviour. Logs technique-usage histogram
// for each sample puzzle so we can see which techniques fire and whether
// the backtrack fallback is needed.
describe('solver verification (informational)', () => {
  for (const [name, puzzle] of Object.entries(PUZZLES)) {
    if (name === 'EASY_SOLUTION') continue;
    it(`summary: ${name}`, () => {
      const board = parseBoard(puzzle);
      const uniq = checkUniqueness(board);
      const result = logicalSolve(board);
      const counts: Record<string, number> = {};
      for (const s of result.steps) {
        counts[s.technique] = (counts[s.technique] ?? 0) + 1;
      }
      // eslint-disable-next-line no-console
      console.log(
        `\n[${name}]\n` +
          `  uniqueness: ${uniq.kind}\n` +
          `  solved: ${isComplete(result.final)}\n` +
          `  totalSteps (logical): ${result.steps.length}\n` +
          `  usedBacktrack: ${result.usedBacktrack}\n` +
          `  techniqueCounts: ${JSON.stringify(counts)}\n` +
          `  finalSerialized: ${serializeBoard(result.final)}`,
      );
      expect(isComplete(result.final)).toBe(true);
    });
  }
});
