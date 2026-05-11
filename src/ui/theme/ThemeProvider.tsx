import { createContext, useContext, useMemo, type ReactNode } from 'react';
import { useColorScheme } from 'react-native';
import { useGame, type ThemeMode } from '../../game/store';
import { makeTheme, type Theme } from './tokens';

type Ctx = {
  theme: Theme;
  mode: ThemeMode;
  isDark: boolean;
  setMode: (m: ThemeMode) => void;
  toggle: () => void;
};

const ThemeContext = createContext<Ctx | null>(null);

export function ThemeProvider({ children }: { children: ReactNode }) {
  const sys = useColorScheme();
  const mode = useGame((s) => s.settings.themeMode);
  const colorBlind = useGame((s) => s.settings.colorBlind);
  const setSetting = useGame((s) => s.setSetting);
  const isDark = mode === 'system' ? sys === 'dark' : mode === 'dark';
  const theme = useMemo(() => makeTheme(isDark, colorBlind), [isDark, colorBlind]);
  const setMode = (m: ThemeMode) => setSetting('themeMode', m);
  const toggle = () => setMode(isDark ? 'light' : 'dark');
  return (
    <ThemeContext.Provider value={{ theme, mode, isDark, setMode, toggle }}>
      {children}
    </ThemeContext.Provider>
  );
}

export function useTheme(): Ctx {
  const ctx = useContext(ThemeContext);
  if (!ctx) throw new Error('useTheme must be used inside <ThemeProvider>');
  return ctx;
}

export type { ThemeMode };
