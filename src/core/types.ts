export type Digit = 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9;

// Board uses plain `number` for ergonomic indexing. Values: 0 (empty) | 1-9.
export type Board = number[][];

// 9-bit mask. bit (n-1) set ⇔ digit n is a candidate.
export type CandidateMask = number;

export type Cell = { r: number; c: number };
export type CellDigit = { r: number; c: number; digit: Digit };

export type Placement = { r: number; c: number; digit: Digit };
export type Elimination = { r: number; c: number; digit: Digit };

export type CellRole = 'base' | 'cover' | 'pivot' | 'pincer' | 'fin' | 'target';
export type CandRole = 'strong' | 'weak' | 'target' | 'fin';
export type UnitKind = 'row' | 'col' | 'box';
export type UnitRole = 'base' | 'cover';

export type Highlight = {
  cells?: Array<{ r: number; c: number; role: CellRole }>;
  candidates?: Array<{ r: number; c: number; digit: Digit; role: CandRole }>;
  units?: Array<{ kind: UnitKind; index: number; role: UnitRole }>;
  links?: Array<{ from: CellDigit; to: CellDigit; kind: 'strong' | 'weak' }>;
};

export type TechniqueId =
  | 'naked_single'
  | 'hidden_single'
  | 'locked_candidates_pointing'
  | 'locked_candidates_claiming'
  | 'naked_pair'
  | 'hidden_pair'
  | 'naked_triple'
  | 'hidden_triple'
  | 'naked_quad'
  | 'hidden_quad'
  | 'x_wing'
  | 'swordfish'
  | 'jellyfish'
  | 'xy_wing'
  | 'xyz_wing'
  | 'w_wing'
  | 'unique_rectangle'
  | 'x_chain'
  | 'xy_chain'
  | 'aic'
  | 'als_xz';

export type Step = {
  technique: TechniqueId;
  placements: Placement[];
  eliminations: Elimination[];
  highlights: Highlight;
  explanationKey: string;
  explanationParams?: Record<string, unknown>;
};
