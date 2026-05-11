export type Theme = {
  bg: string;
  bgElevated: string;
  text: string;
  textMuted: string;
  cellBg: string;
  cellBgGiven: string;
  cellBgSelected: string;
  cellBgPeer: string;
  cellBgSameDigit: string;
  cellBgInvalid: string;
  textGiven: string;
  textInput: string;
  textConflict: string;
  textPencil: string;
  gridLine: string;
  gridLineBox: string;
  buttonBg: string;
  buttonBgActive: string;
  border: string;
  accent: string;
  scrim: string;
};

const lightBase: Theme = {
  bg: '#ffffff',
  bgElevated: '#f7f7f7',
  text: '#1a1a1a',
  textMuted: '#6b6b6b',
  cellBg: '#ffffff',
  cellBgGiven: '#f4f5f7',
  cellBgSelected: '#cfe1ff',
  cellBgPeer: '#eef2f7',
  cellBgSameDigit: '#d8e9ff',
  cellBgInvalid: '#fde2e2',
  textGiven: '#1a1a1a',
  textInput: '#2563eb',
  textConflict: '#dc2626',
  textPencil: '#6b6b6b',
  gridLine: '#d4d4d8',
  gridLineBox: '#1a1a1a',
  buttonBg: '#f0f0f0',
  buttonBgActive: '#cfe1ff',
  border: '#d4d4d8',
  accent: '#2563eb',
  scrim: 'rgba(0,0,0,0.35)',
};

const darkBase: Theme = {
  bg: '#0a0a0a',
  bgElevated: '#161618',
  text: '#ededed',
  textMuted: '#999999',
  cellBg: '#161618',
  cellBgGiven: '#1f1f22',
  cellBgSelected: '#1e3a5f',
  cellBgPeer: '#202024',
  cellBgSameDigit: '#2a4870',
  cellBgInvalid: '#4a1d1d',
  textGiven: '#ededed',
  textInput: '#60a5fa',
  textConflict: '#f87171',
  textPencil: '#888888',
  gridLine: '#2a2a2e',
  gridLineBox: '#ededed',
  buttonBg: '#1f1f22',
  buttonBgActive: '#1e3a5f',
  border: '#2a2a2e',
  accent: '#60a5fa',
  scrim: 'rgba(0,0,0,0.55)',
};

export function makeTheme(isDark: boolean, colorBlind: boolean): Theme {
  const base = isDark ? darkBase : lightBase;
  if (!colorBlind) return base;
  return {
    ...base,
    textConflict: isDark ? '#fbbf24' : '#b45309',
    cellBgInvalid: isDark ? '#3a2a0d' : '#fef0c7',
  };
}

export const lightTheme = lightBase;
export const darkTheme = darkBase;
