import type { Digit, Elimination, Step, TechniqueId, UnitKind } from '../../core/types';
import { hasCandidate, maskToDigits, popcount } from '../../core/candidates';
import { BOXES, COLS, ROWS, type Unit } from '../../core/units';
import type { SolverContext, Technique } from '../Technique';

type SubsetSize = 2 | 3 | 4;

const TECH_BY_SIZE: Record<SubsetSize, TechniqueId> = {
  2: 'hidden_pair',
  3: 'hidden_triple',
  4: 'hidden_quad',
};

const KEY_BY_SIZE: Record<SubsetSize, string> = {
  2: 'techniques.hidden_pair.step',
  3: 'techniques.hidden_triple.step',
  4: 'techniques.hidden_quad.step',
};

const UNIT_LIST: Array<{ kind: UnitKind; index: number; cells: Unit }> = [
  ...ROWS.map((cells, index) => ({ kind: 'row' as UnitKind, index, cells })),
  ...COLS.map((cells, index) => ({ kind: 'col' as UnitKind, index, cells })),
  ...BOXES.map((cells, index) => ({ kind: 'box' as UnitKind, index, cells })),
];

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
  // For each unsolved digit in this unit: bitmask of cell positions inside the unit
  const digitInfo: Array<{ digit: Digit; cellMask: number }> = [];
  for (let d = 1; d <= 9; d++) {
    const digit = d as Digit;
    let placed = false;
    let mask = 0;
    for (let i = 0; i < unit.cells.length; i++) {
      const [r, c] = unit.cells[i];
      if (board[r][c] === digit) {
        placed = true;
        break;
      }
      if (board[r][c] === 0 && hasCandidate(candidates[r][c], digit)) {
        mask |= 1 << i;
      }
    }
    if (placed) continue;
    if (mask === 0) continue;
    digitInfo.push({ digit, cellMask: mask });
  }
  if (digitInfo.length < size) return null;

  for (const combo of combinations(digitInfo.length, size)) {
    let union = 0;
    for (const i of combo) union |= digitInfo[i].cellMask;
    if (popcount(union) !== size) continue;

    const subsetDigits = combo.map((i) => digitInfo[i].digit);
    const subsetDigitMask = subsetDigits.reduce(
      (m, d) => m | (1 << (d - 1)),
      0,
    );

    const targets: Array<[number, number]> = [];
    const eliminations: Elimination[] = [];
    for (let i = 0; i < unit.cells.length; i++) {
      if ((union & (1 << i)) === 0) continue;
      const [r, c] = unit.cells[i];
      targets.push([r, c]);
      const extra = candidates[r][c] & ~subsetDigitMask;
      if (extra === 0) continue;
      for (const d of maskToDigits(extra)) {
        eliminations.push({ r, c, digit: d });
      }
    }
    if (eliminations.length === 0) continue;

    return {
      technique: TECH_BY_SIZE[size],
      placements: [],
      eliminations,
      highlights: {
        cells: targets.map(([r, c]) => ({ r, c, role: 'base' })),
        candidates: targets.flatMap(([r, c]) =>
          subsetDigits
            .filter((d) => hasCandidate(candidates[r][c], d))
            .map((d) => ({ r, c, digit: d, role: 'strong' as const })),
        ),
        units: [{ kind: unit.kind, index: unit.index, role: 'base' }],
      },
      explanationKey: KEY_BY_SIZE[size],
      explanationParams: {
        unit: unit.kind,
        unitIndex: unit.index + 1,
        digits: subsetDigits,
        size,
      },
    };
  }
  return null;
}

function findHiddenSubset(ctx: SolverContext, size: SubsetSize): Step | null {
  for (const u of UNIT_LIST) {
    const step = findInUnit(ctx, u, size);
    if (step) return step;
  }
  return null;
}

export const hiddenPair: Technique = {
  id: 'hidden_pair',
  level: 2,
  find: (ctx) => findHiddenSubset(ctx, 2),
};

export const hiddenTriple: Technique = {
  id: 'hidden_triple',
  level: 2,
  find: (ctx) => findHiddenSubset(ctx, 3),
};

export const hiddenQuad: Technique = {
  id: 'hidden_quad',
  level: 3,
  find: (ctx) => findHiddenSubset(ctx, 4),
};
