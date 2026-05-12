import type { Technique } from './Technique';
import { hiddenPair, hiddenQuad, hiddenTriple } from './techniques/hiddenSubset';
import { hiddenSingle } from './techniques/hiddenSingle';
import { lockedCandidatesClaiming } from './techniques/lockedCandidatesClaiming';
import { lockedCandidatesPointing } from './techniques/lockedCandidatesPointing';
import { nakedPair, nakedQuad, nakedTriple } from './techniques/nakedSubset';
import { nakedSingle } from './techniques/nakedSingle';
import { xWing } from './techniques/xWing';

// Add new techniques here. Sorted by `level` ascending — solver tries simpler first.
const TECHNIQUE_LIST: Technique[] = [
  nakedSingle,
  hiddenSingle,
  lockedCandidatesPointing,
  lockedCandidatesClaiming,
  nakedPair,
  hiddenPair,
  nakedTriple,
  hiddenTriple,
  nakedQuad,
  hiddenQuad,
  xWing,
];

export const TECHNIQUES: ReadonlyArray<Technique> = [...TECHNIQUE_LIST].sort(
  (a, b) => a.level - b.level,
);
