import type { Board, CandidateMask, Step, TechniqueId } from '../core/types';

export type SolverContext = {
  board: Board;
  candidates: CandidateMask[][];
};

// Every technique implements this interface. Adding a new one is:
//   1. create src/solver/techniques/<id>.ts that exports a Technique
//   2. register it in src/solver/registry.ts
// The solver will pick it up automatically, sorted by `level` ascending.
export interface Technique {
  readonly id: TechniqueId;
  readonly level: number;
  find(ctx: SolverContext): Step | null;
}
