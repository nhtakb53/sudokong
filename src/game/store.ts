import AsyncStorage from '@react-native-async-storage/async-storage';
import { create } from 'zustand';
import { createJSONStorage, persist } from 'zustand/middleware';
import type { Board, Cell, Digit, Step } from '../core/types';
import { cloneBoard, hasConflicts, isComplete, parseBoard } from '../core/board';
import { computeAllCandidates } from '../core/candidates';
import { PEERS } from '../core/units';
import { PUZZLES } from '../data/samplePuzzles';
import { backtrackSolve } from '../solver/backtrack';
import { nextStep } from '../solver/solver';

type Pencils = number[][];

const emptyPencils = (): Pencils =>
  Array.from({ length: 9 }, () => Array(9).fill(0));

const clonePencils = (p: Pencils): Pencils => p.map((row) => [...row]);

type Snapshot = { current: Board; pencils: Pencils };

export type GameMode = 'value' | 'pencil';

export type FontScale = 'sm' | 'md' | 'lg';

export type ThemeMode = 'system' | 'light' | 'dark';

export type Lang = 'ko' | 'en';

export type Settings = {
  highlightSameDigit: boolean;
  highlightPeers: boolean;
  colorBlind: boolean;
  fontScale: FontScale;
  themeMode: ThemeMode;
  lang: Lang;
};

const defaultSettings: Settings = {
  highlightSameDigit: true,
  highlightPeers: true,
  colorBlind: false,
  fontScale: 'md',
  themeMode: 'system',
  lang: 'ko',
};

type State = {
  initial: Board;
  current: Board;
  solution: Board;
  pencils: Pencils;
  selectedCell: Cell | null;
  mode: GameMode;
  autoPencil: boolean;
  hint: Step | null;
  history: Snapshot[];
  historyIndex: number;
  startedAt: number;
  completedAt: number | null;
  pausedAt: number | null;
  settings: Settings;
  lockedDigit: Digit | null;
  invalidCells: string[];
  validateActive: boolean;
  select: (r: number, c: number) => void;
  setMode: (mode: GameMode) => void;
  toggleMode: () => void;
  toggleAutoPencil: () => void;
  inputDigit: (d: Digit) => void;
  erase: () => void;
  undo: () => void;
  redo: () => void;
  newGame: (puzzleStr?: string) => void;
  requestHint: () => void;
  clearHint: () => void;
  applyHint: () => void;
  validate: () => void;
  clearValidation: () => void;
  fillAllCandidates: () => void;
  setSetting: <K extends keyof Settings>(key: K, value: Settings[K]) => void;
  setLockedDigit: (d: Digit | null) => void;
  importPuzzle: (str: string) => ImportResult;
  pause: () => void;
  resume: () => void;
};

export type ImportError = 'length' | 'chars' | 'conflict' | 'unsolvable';
export type ImportResult = { ok: true } | { ok: false; error: ImportError };

const seed = (puzzleStr: string) => {
  const initial = parseBoard(puzzleStr);
  const solved = cloneBoard(initial);
  backtrackSolve(solved);
  return {
    initial,
    current: cloneBoard(initial),
    solution: solved,
    pencils: emptyPencils(),
  };
};

const computeCompletion = (
  current: Board,
  prev: number | null,
): number | null => {
  if (isComplete(current) && !hasConflicts(current)) {
    return prev ?? Date.now();
  }
  return null;
};

export function getRemainingCounts(board: Board): Record<number, number> {
  const counts: Record<number, number> = {
    1: 9, 2: 9, 3: 9, 4: 9, 5: 9, 6: 9, 7: 9, 8: 9, 9: 9,
  };
  for (let r = 0; r < 9; r++) {
    for (let c = 0; c < 9; c++) {
      const v = board[r][c];
      if (v !== 0) counts[v]--;
    }
  }
  return counts;
}

const initialSeed = seed(PUZZLES.EASY);

export const useGame = create<State>()(
  persist(
    (set, get) => {
      const pushHistory = (snap: Snapshot) => {
        const s = get();
        const truncated = s.history.slice(0, s.historyIndex + 1);
        const next = [
          ...truncated,
          { current: cloneBoard(snap.current), pencils: clonePencils(snap.pencils) },
        ];
        set({
          current: snap.current,
          pencils: snap.pencils,
          history: next,
          historyIndex: next.length - 1,
          completedAt: computeCompletion(snap.current, s.completedAt),
          validateActive: false,
          invalidCells: [],
        });
      };

      return {
        ...initialSeed,
        selectedCell: null,
        mode: 'value',
        autoPencil: true,
        hint: null,
        history: [
          {
            current: cloneBoard(initialSeed.current),
            pencils: clonePencils(initialSeed.pencils),
          },
        ],
        historyIndex: 0,
        startedAt: Date.now(),
        completedAt: null,
        pausedAt: null,
        settings: defaultSettings,
        lockedDigit: null,
        invalidCells: [],
        validateActive: false,

        select: (r, c) => set({ selectedCell: { r, c } }),
        setMode: (mode) => set({ mode }),
        toggleMode: () =>
          set((s) => ({ mode: s.mode === 'value' ? 'pencil' : 'value' })),
        toggleAutoPencil: () => set((s) => ({ autoPencil: !s.autoPencil })),

        inputDigit: (d) => {
          const s = get();
          // No selection or selected cell is a given clue -> toggle highlight
          // for that digit across the board instead of entering a value.
          if (
            !s.selectedCell ||
            s.initial[s.selectedCell.r][s.selectedCell.c] !== 0
          ) {
            set({ lockedDigit: s.lockedDigit === d ? null : d });
            return;
          }
          const { r, c } = s.selectedCell;
          const nextCurrent = cloneBoard(s.current);
          const nextPencils = clonePencils(s.pencils);
          if (s.mode === 'value') {
            const placing = nextCurrent[r][c] !== d;
            nextCurrent[r][c] = placing ? d : 0;
            nextPencils[r][c] = 0;
            if (placing && s.autoPencil) {
              const removeMask = ~(1 << (d - 1));
              for (const [pr, pc] of PEERS[r][c]) {
                nextPencils[pr][pc] &= removeMask;
              }
            }
          } else {
            if (nextCurrent[r][c] !== 0) return;
            nextPencils[r][c] = nextPencils[r][c] ^ (1 << (d - 1));
          }
          pushHistory({ current: nextCurrent, pencils: nextPencils });
        },

        erase: () => {
          const s = get();
          if (!s.selectedCell) return;
          const { r, c } = s.selectedCell;
          if (s.initial[r][c] !== 0) return;
          if (s.current[r][c] === 0 && s.pencils[r][c] === 0) return;
          const nextCurrent = cloneBoard(s.current);
          const nextPencils = clonePencils(s.pencils);
          nextCurrent[r][c] = 0;
          nextPencils[r][c] = 0;
          pushHistory({ current: nextCurrent, pencils: nextPencils });
        },

        undo: () => {
          const s = get();
          if (s.historyIndex <= 0) return;
          const idx = s.historyIndex - 1;
          const snap = s.history[idx];
          const current = cloneBoard(snap.current);
          set({
            historyIndex: idx,
            current,
            pencils: clonePencils(snap.pencils),
            completedAt: computeCompletion(current, s.completedAt),
            validateActive: false,
            invalidCells: [],
          });
        },

        redo: () => {
          const s = get();
          if (s.historyIndex >= s.history.length - 1) return;
          const idx = s.historyIndex + 1;
          const snap = s.history[idx];
          const current = cloneBoard(snap.current);
          set({
            historyIndex: idx,
            current,
            pencils: clonePencils(snap.pencils),
            completedAt: computeCompletion(current, s.completedAt),
            validateActive: false,
            invalidCells: [],
          });
        },

        newGame: (puzzleStr) => {
          const seeded = seed(puzzleStr ?? PUZZLES.EASY);
          set({
            ...seeded,
            selectedCell: null,
            mode: 'value',
            hint: null,
            history: [
              {
                current: cloneBoard(seeded.current),
                pencils: clonePencils(seeded.pencils),
              },
            ],
            historyIndex: 0,
            startedAt: Date.now(),
            completedAt: null,
            pausedAt: null,
            lockedDigit: null,
            invalidCells: [],
            validateActive: false,
          });
        },

        requestHint: () => {
          const s = get();
          const step = nextStep(s.current);
          set({ hint: step });
        },

        clearHint: () => set({ hint: null }),

        applyHint: () => {
          const s = get();
          if (!s.hint) return;
          const nextCurrent = cloneBoard(s.current);
          const nextPencils = clonePencils(s.pencils);
          for (const p of s.hint.placements) {
            nextCurrent[p.r][p.c] = p.digit;
            nextPencils[p.r][p.c] = 0;
            if (s.autoPencil) {
              const removeMask = ~(1 << (p.digit - 1));
              for (const [pr, pc] of PEERS[p.r][p.c]) {
                nextPencils[pr][pc] &= removeMask;
              }
            }
          }
          for (const e of s.hint.eliminations) {
            nextPencils[e.r][e.c] &= ~(1 << (e.digit - 1));
          }
          pushHistory({ current: nextCurrent, pencils: nextPencils });
          set({ hint: null });
        },

        validate: () => {
          const s = get();
          if (s.validateActive) {
            set({ validateActive: false, invalidCells: [] });
            return;
          }
          const invalid: string[] = [];
          for (let r = 0; r < 9; r++) {
            for (let c = 0; c < 9; c++) {
              const v = s.current[r][c];
              if (v !== 0 && v !== s.solution[r][c]) {
                invalid.push(`${r},${c}`);
              }
            }
          }
          set({ validateActive: true, invalidCells: invalid });
        },

        clearValidation: () => set({ validateActive: false, invalidCells: [] }),

        fillAllCandidates: () => {
          const s = get();
          const cands = computeAllCandidates(s.current);
          const nextPencils = clonePencils(s.pencils);
          for (let r = 0; r < 9; r++) {
            for (let c = 0; c < 9; c++) {
              if (s.current[r][c] === 0) {
                nextPencils[r][c] = cands[r][c];
              }
            }
          }
          pushHistory({ current: cloneBoard(s.current), pencils: nextPencils });
        },

        setSetting: (key, value) =>
          set((s) => ({ settings: { ...s.settings, [key]: value } })),

        setLockedDigit: (d) => set({ lockedDigit: d }),

        importPuzzle: (str) => {
          const cleaned = str.replace(/\s+/g, '');
          if (cleaned.length !== 81) return { ok: false, error: 'length' };
          if (!/^[0-9.]+$/.test(cleaned)) return { ok: false, error: 'chars' };
          let parsed: Board;
          try {
            parsed = parseBoard(cleaned);
          } catch {
            return { ok: false, error: 'chars' };
          }
          if (hasConflicts(parsed)) return { ok: false, error: 'conflict' };
          const solved = cloneBoard(parsed);
          if (!backtrackSolve(solved)) return { ok: false, error: 'unsolvable' };
          set({
            initial: parsed,
            current: cloneBoard(parsed),
            solution: solved,
            pencils: emptyPencils(),
            selectedCell: null,
            mode: 'value',
            hint: null,
            history: [
              {
                current: cloneBoard(parsed),
                pencils: emptyPencils(),
              },
            ],
            historyIndex: 0,
            startedAt: Date.now(),
            completedAt: null,
            pausedAt: null,
            lockedDigit: null,
            invalidCells: [],
            validateActive: false,
          });
          return { ok: true };
        },

        pause: () => {
          const s = get();
          if (s.completedAt != null || s.pausedAt != null) return;
          set({ pausedAt: Date.now() });
        },

        resume: () => {
          const s = get();
          if (s.pausedAt == null) return;
          const delta = Date.now() - s.pausedAt;
          set({ startedAt: s.startedAt + delta, pausedAt: null });
        },
      };
    },
    {
      name: 'sudokong:game',
      version: 1,
      storage: createJSONStorage(() => AsyncStorage),
      partialize: (state) => ({
        initial: state.initial,
        current: state.current,
        solution: state.solution,
        pencils: state.pencils,
        history: state.history,
        historyIndex: state.historyIndex,
        mode: state.mode,
        autoPencil: state.autoPencil,
        startedAt: state.startedAt,
        completedAt: state.completedAt,
        pausedAt: state.pausedAt,
        settings: state.settings,
      }),
      merge: (persisted, current) => {
        const p = (persisted ?? {}) as Partial<State>;
        const merged: State = {
          ...current,
          ...p,
          settings: { ...defaultSettings, ...(p.settings ?? {}) },
        };
        // If the persisted timer is older than 3h and the puzzle isn't done,
        // assume the user was idle and reset the clock.
        const IDLE_RESET_MS = 3 * 60 * 60 * 1000;
        if (
          merged.completedAt == null &&
          merged.startedAt != null &&
          Date.now() - merged.startedAt > IDLE_RESET_MS
        ) {
          merged.startedAt = Date.now();
          merged.pausedAt = null;
        }
        return merged;
      },
    },
  ),
);
