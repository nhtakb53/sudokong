import { useEffect } from 'react';
import { Platform } from 'react-native';
import type { Digit } from '../../core/types';
import { useGame } from '../../game/store';

const isEditableTarget = (target: EventTarget | null): boolean => {
  if (!target || typeof window === 'undefined') return false;
  if (!(target instanceof HTMLElement)) return false;
  const tag = target.tagName?.toLowerCase();
  if (tag === 'input' || tag === 'textarea' || tag === 'select') return true;
  if (target.isContentEditable) return true;
  return false;
};

const DIGIT_CODES: Record<string, Digit> = {
  Digit1: 1, Digit2: 2, Digit3: 3, Digit4: 4, Digit5: 5,
  Digit6: 6, Digit7: 7, Digit8: 8, Digit9: 9,
  Numpad1: 1, Numpad2: 2, Numpad3: 3, Numpad4: 4, Numpad5: 5,
  Numpad6: 6, Numpad7: 7, Numpad8: 8, Numpad9: 9,
};

const ERASE_CODES = new Set(['Digit0', 'Numpad0', 'Backspace', 'Delete']);

// Web-only keyboard shortcuts. Uses `e.code` (physical key) so the bindings
// work even when a Korean IME swaps `e.key` to Hangul characters.
export function useKeyboardShortcuts() {
  useEffect(() => {
    if (Platform.OS !== 'web') return;
    if (typeof window === 'undefined') return;

    const handler = (e: KeyboardEvent) => {
      if (isEditableTarget(e.target)) return;
      if (e.isComposing) return;

      const s = useGame.getState();
      const code = e.code;
      const mod = e.metaKey || e.ctrlKey;

      // Cmd/Ctrl+Z = undo, Cmd/Ctrl+Shift+Z = redo
      if (mod && code === 'KeyZ') {
        e.preventDefault();
        if (e.shiftKey) s.redo();
        else s.undo();
        return;
      }
      // Cmd/Ctrl+Y = redo
      if (mod && code === 'KeyY') {
        e.preventDefault();
        s.redo();
        return;
      }

      // Anything else with a modifier: let the browser handle it
      if (mod) return;

      // 1-9: input digit
      const digit = DIGIT_CODES[code];
      if (digit !== undefined) {
        e.preventDefault();
        s.inputDigit(digit);
        return;
      }

      // 0 / Backspace / Delete: erase
      if (ERASE_CODES.has(code)) {
        e.preventDefault();
        s.erase();
        return;
      }

      // Arrow keys: move selection
      if (
        code === 'ArrowUp' ||
        code === 'ArrowDown' ||
        code === 'ArrowLeft' ||
        code === 'ArrowRight'
      ) {
        e.preventDefault();
        const sel = s.selectedCell;
        if (!sel) {
          s.select(0, 0);
          return;
        }
        let { r, c } = sel;
        if (code === 'ArrowUp') r = Math.max(0, r - 1);
        else if (code === 'ArrowDown') r = Math.min(8, r + 1);
        else if (code === 'ArrowLeft') c = Math.max(0, c - 1);
        else c = Math.min(8, c + 1);
        s.select(r, c);
        return;
      }

      // Space / P: toggle pencil mode
      if (code === 'Space' || code === 'KeyP') {
        e.preventDefault();
        s.toggleMode();
        return;
      }

      // H: request hint
      if (code === 'KeyH') {
        e.preventDefault();
        s.requestHint();
        return;
      }

      // V: validate (toggle)
      if (code === 'KeyV') {
        e.preventDefault();
        s.validate();
        return;
      }

      // Escape: dismiss hint
      if (code === 'Escape') {
        if (s.hint) {
          e.preventDefault();
          s.clearHint();
        }
        return;
      }
    };

    window.addEventListener('keydown', handler);
    return () => window.removeEventListener('keydown', handler);
  }, []);
}
