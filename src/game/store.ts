import { create } from 'zustand';
import type { Board, Cell, Digit } from '../core/types';
import { cloneBoard, parseBoard } from '../core/board';
import { PUZZLES } from '../data/samplePuzzles';

type Pencils = number[][];

const emptyPencils = (): Pencils =>
  Array.from({ length: 9 }, () => Array(9).fill(0));

const clonePencils = (p: Pencils): Pencils => p.map((row) => [...row]);

type Snapshot = { current: Board; pencils: Pencils };

export type GameMode = 'value' | 'pencil';

type State = {
  initial: Board;
  current: Board;
  pencils: Pencils;
  selectedCell: Cell | null;
  mode: GameMode;
  history: Snapshot[];
  historyIndex: number;
  select: (r: number, c: number) => void;
  setMode: (mode: GameMode) => void;
  toggleMode: () => void;
  inputDigit: (d: Digit) => void;
  erase: () => void;
  undo: () => void;
  redo: () => void;
  newGame: (puzzleStr?: string) => void;
};

const seed = (puzzleStr: string) => {
  const initial = parseBoard(puzzleStr);
  return {
    initial,
    current: cloneBoard(initial),
    pencils: emptyPencils(),
  };
};

const initialSeed = seed(PUZZLES.EASY);

export const useGame = create<State>((set, get) => {
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
    });
  };

  return {
    ...initialSeed,
    selectedCell: null,
    mode: 'value',
    history: [
      {
        current: cloneBoard(initialSeed.current),
        pencils: clonePencils(initialSeed.pencils),
      },
    ],
    historyIndex: 0,

    select: (r, c) => set({ selectedCell: { r, c } }),
    setMode: (mode) => set({ mode }),
    toggleMode: () =>
      set((s) => ({ mode: s.mode === 'value' ? 'pencil' : 'value' })),

    inputDigit: (d) => {
      const s = get();
      if (!s.selectedCell) return;
      const { r, c } = s.selectedCell;
      if (s.initial[r][c] !== 0) return;
      const nextCurrent = cloneBoard(s.current);
      const nextPencils = clonePencils(s.pencils);
      if (s.mode === 'value') {
        nextCurrent[r][c] = nextCurrent[r][c] === d ? 0 : d;
        nextPencils[r][c] = 0;
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
      set({
        historyIndex: idx,
        current: cloneBoard(snap.current),
        pencils: clonePencils(snap.pencils),
      });
    },

    redo: () => {
      const s = get();
      if (s.historyIndex >= s.history.length - 1) return;
      const idx = s.historyIndex + 1;
      const snap = s.history[idx];
      set({
        historyIndex: idx,
        current: cloneBoard(snap.current),
        pencils: clonePencils(snap.pencils),
      });
    },

    newGame: (puzzleStr) => {
      const seeded = seed(puzzleStr ?? PUZZLES.EASY);
      set({
        ...seeded,
        selectedCell: null,
        mode: 'value',
        history: [
          {
            current: cloneBoard(seeded.current),
            pencils: clonePencils(seeded.pencils),
          },
        ],
        historyIndex: 0,
      });
    },
  };
});
