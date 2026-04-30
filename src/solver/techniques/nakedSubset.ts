import type { Elimination, Step, TechniqueId, UnitKind } from '../../core/types';
import { maskToDigits, popcount } from '../../core/candidates';
import { BOXES, COLS, ROWS, type Unit } from '../../core/units';
import type { SolverContext, Technique } from '../Technique';

type SubsetSize = 2 | 3 | 4;

const TECH_BY_SIZE: Record<SubsetSize, TechniqueId> = {
  2: 'naked_pair',
  3: 'naked_triple',
  4: 'naked_quad',
};

const KEY_BY_SIZE: Record<SubsetSize, string> = {
  2: 'techniques.naked_pair.step',
  3: 'techniques.naked_triple.step',
  4: 'techniques.naked_quad.step',
};

const UNIT_LIST: Array<{ kind: UnitKind; index: number; cells: Unit }> = [
  ...ROWS.map((cells, index) => ({ kind: 'row' as UnitKind, index, cells })),
  ...COLS.map((cells, index) => ({ kind: 'col' as UnitKind, index, cells })),
  ...BOXES.map((cells, index) => ({ kind: 'box' as UnitKind, index, cells })),
];

// Generic k-combinations of indices [0..n).
function* combinations(n: number, k: number, start = 0): Generator<number[]> {
  if (k === 0) {
    yield [];
    return;
  }
  for (let i = start; i <= n - k; i++) {
    for (const rest of combinations(n, k - 1, i + 1)) {
      yield [i, ...rest];
    }
  }
}

function findInUnit(
  ctx: SolverContext,
  unit: { kind: UnitKind; index: number; cells: Unit },
  size: SubsetSize,
): Step | null {
  const { board, candidates } = ctx;
  const empties: Array<{ r: number; c: number; mask: number }> = [];
  for (const [r, c] of unit.cells) {
    if (board[r][c] !== 0) continue;
    const m = candidates[r][c];
    if (m !== 0 && popcount(m) <= size) empties.push({ r, c, mask: m });
  }
  if (empties.length < size) return null;

  for (const combo of combinations(empties.length, size)) {
    let union = 0;
    for (const i of combo) union |= empties[i].mask;
    if (popcount(union) !== size) continue;

    const subsetSet = new Set(combo);
    const eliminations: Elimination[] = [];
    for (let i = 0; i < unit.cells.length; i++) {
      const [r, c] = unit.cells[i];
      if (board[r][c] !== 0) continue;
      // skip the subset cells themselves
      const idxInEmpties = empties.findIndex((e) => e.r === r && e.c === c);
      if (idxInEmpties !== -1 && subsetSet.has(idxInEmpties)) continue;
      const overlap = candidates[r][c] & union;
      if (overlap === 0) continue;
      for (const d of maskToDigits(overlap)) {
        eliminations.push({ r, c, digit: d });
      }
    }
    if (eliminations.length === 0) continue;

    const subsetCells = combo.map((i) => empties[i]);
    const digits = maskToDigits(union);
    return {
      technique: TECH_BY_SIZE[size],
      placements: [],
      eliminations,
      highlights: {
        cells: subsetCells.map(({ r, c }) => ({ r, c, role: 'base' })),
        candidates: subsetCells.flatMap(({ r, c, mask }) =>
          maskToDigits(mask).map((d) => ({ r, c, digit: d, role: 'strong' as const })),
        ),
        units: [{ kind: unit.kind, index: unit.index, role: 'base' }],
      },
      explanationKey: KEY_BY_SIZE[size],
      explanationParams: {
        unit: unit.kind,
        unitIndex: unit.index + 1,
        digits,
        size,
      },
    };
  }
  return null;
}

function findNakedSubset(ctx: SolverContext, size: SubsetSize): Step | null {
  for (const u of UNIT_LIST) {
    const step = findInUnit(ctx, u, size);
    if (step) return step;
  }
  return null;
}

export const nakedPair: Technique = {
  id: 'naked_pair',
  level: 2,
  find: (ctx) => findNakedSubset(ctx, 2),
};

export const nakedTriple: Technique = {
  id: 'naked_triple',
  level: 2,
  find: (ctx) => findNakedSubset(ctx, 3),
};

export const nakedQuad: Technique = {
  id: 'naked_quad',
  level: 3,
  find: (ctx) => findNakedSubset(ctx, 4),
};
