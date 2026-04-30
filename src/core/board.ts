import type { Board } from './types';

export const SIZE = 9;
export const BOX = 3;

export function emptyBoard(): Board {
  return Array.from({ length: SIZE }, () => Array(SIZE).fill(0));
}

export function cloneBoard(board: Board): Board {
  return board.map((row) => [...row]);
}

export function parseBoard(str: string): Board {
  const cleaned = str.replace(/\s+/g, '');
  if (cleaned.length !== 81) {
    throw new Error(`parseBoard: expected 81 chars, got ${cleaned.length}`);
  }
  const board = emptyBoard();
  for (let i = 0; i < 81; i++) {
    const ch = cleaned[i];
    const r = Math.floor(i / 9);
    const c = i % 9;
    if (ch === '.' || ch === '0') {
      board[r][c] = 0;
    } else {
      const n = Number(ch);
      if (!Number.isInteger(n) || n < 1 || n > 9) {
        throw new Error(`parseBoard: invalid char '${ch}' at index ${i}`);
      }
      board[r][c] = n;
    }
  }
  return board;
}

export function serializeBoard(board: Board): string {
  return board.flat().map((v) => (v === 0 ? '.' : String(v))).join('');
}

export function boxIndex(r: number, c: number): number {
  return Math.floor(r / 3) * 3 + Math.floor(c / 3);
}

export function isComplete(board: Board): boolean {
  for (let r = 0; r < 9; r++) {
    for (let c = 0; c < 9; c++) {
      if (board[r][c] === 0) return false;
    }
  }
  return true;
}

export function hasConflicts(board: Board): boolean {
  for (let i = 0; i < 9; i++) {
    const rowSeen = new Set<number>();
    const colSeen = new Set<number>();
    for (let j = 0; j < 9; j++) {
      const rv = board[i][j];
      if (rv !== 0) {
        if (rowSeen.has(rv)) return true;
        rowSeen.add(rv);
      }
      const cv = board[j][i];
      if (cv !== 0) {
        if (colSeen.has(cv)) return true;
        colSeen.add(cv);
      }
    }
  }
  for (let br = 0; br < 3; br++) {
    for (let bc = 0; bc < 3; bc++) {
      const seen = new Set<number>();
      for (let dr = 0; dr < 3; dr++) {
        for (let dc = 0; dc < 3; dc++) {
          const v = board[br * 3 + dr][bc * 3 + dc];
          if (v !== 0) {
            if (seen.has(v)) return true;
            seen.add(v);
          }
        }
      }
    }
  }
  return false;
}

export function isValidPlacement(
  board: Board,
  r: number,
  c: number,
  num: number,
): boolean {
  for (let i = 0; i < 9; i++) {
    if (board[r][i] === num) return false;
    if (board[i][c] === num) return false;
  }
  const br = Math.floor(r / 3) * 3;
  const bc = Math.floor(c / 3) * 3;
  for (let i = 0; i < 3; i++) {
    for (let j = 0; j < 3; j++) {
      if (board[br + i][bc + j] === num) return false;
    }
  }
  return true;
}
