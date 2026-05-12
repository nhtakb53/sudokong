import { describe, expect, it } from 'vitest';
import { parseBoard } from '../core/board';
import { computeAllCandidates } from '../core/candidates';
import { COURSES } from '../learn/courses';
import { applyStep, nextStep } from '../solver/solver';

function reachesTechnique(start: string, target: string, maxSteps = 200) {
  const board = parseBoard(start);
  const candidates = computeAllCandidates(board);
  let step = nextStep(board, candidates);
  let count = 0;
  while (step && step.technique !== target && count < maxSteps) {
    if (step.placements.length === 0 && step.eliminations.length === 0) break;
    applyStep(board, step, candidates);
    step = nextStep(board, candidates);
    count++;
  }
  return step?.technique === target;
}

// Lessons that have a dedicated, hand-curated example board where the target
// technique is guaranteed to appear. Other lessons rely on the LessonViewer
// fallback (mismatch banner + first available step).
const VERIFIED_TECHNIQUE_IDS = new Set<string>([
  'naked_single',
  'hidden_single',
  'locked_candidates_pointing',
  'locked_candidates_claiming',
  'naked_pair',
  'hidden_pair',
  'hidden_triple',
  'naked_quad',
  'x_wing',
]);

describe('lesson example boards', () => {
  for (const course of COURSES) {
    for (const lesson of course.lessons) {
      if (
        lesson.status !== 'available' ||
        !lesson.example ||
        !lesson.techniqueId ||
        !VERIFIED_TECHNIQUE_IDS.has(lesson.techniqueId)
      ) {
        continue;
      }
      it(`example for "${lesson.id}" reaches technique ${lesson.techniqueId}`, () => {
        expect(lesson.example!.length).toBe(81);
        expect(reachesTechnique(lesson.example!, lesson.techniqueId!)).toBe(
          true,
        );
      });
    }
  }
});
