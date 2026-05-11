import { StatusBar } from 'expo-status-bar';
import { useEffect, useState } from 'react';
import { I18nextProvider } from 'react-i18next';
import { AppState, Platform, useWindowDimensions, View } from 'react-native';
import { useGame } from './src/game/store';
import i18n from './src/i18n';
import { LearnSidebar } from './src/ui/components/LearnSidebar';
import { PlayScreen } from './src/ui/screens/PlayScreen';
import { ThemeProvider, useTheme } from './src/ui/theme/ThemeProvider';

const SIDEBAR_BREAKPOINT = 768;
const SIDEBAR_WIDTH = 300;

function useWebGlobalStyles() {
  useEffect(() => {
    if (Platform.OS !== 'web' || typeof document === 'undefined') return;
    const id = 'sudokong-global-styles';
    if (document.getElementById(id)) return;
    const el = document.createElement('style');
    el.id = id;
    el.textContent = `
      * { -webkit-tap-highlight-color: transparent; }
      *:focus,
      *:focus-visible,
      *:focus-within {
        outline: none !important;
        outline-style: none !important;
        outline-width: 0 !important;
        box-shadow: none !important;
      }
    `;
    document.head.appendChild(el);
  }, []);
}

function Inner() {
  const { theme, isDark } = useTheme();
  useWebGlobalStyles();
  const { width } = useWindowDimensions();
  const showSidebar = width >= SIDEBAR_BREAKPOINT;
  return (
    <View
      style={{
        flex: 1,
        backgroundColor: theme.bg,
        flexDirection: 'row',
      }}
    >
      {showSidebar && (
        <View style={{ width: SIDEBAR_WIDTH }}>
          <LearnSidebar />
        </View>
      )}
      <View style={{ flex: 1 }}>
        <PlayScreen />
      </View>
      <StatusBar style={isDark ? 'light' : 'dark'} />
    </View>
  );
}

function useStoreHydrated(): boolean {
  const [hydrated, setHydrated] = useState(() =>
    useGame.persist.hasHydrated(),
  );
  useEffect(() => {
    if (hydrated) return;
    const unsub = useGame.persist.onFinishHydration(() => setHydrated(true));
    return () => {
      unsub();
    };
  }, [hydrated]);
  return hydrated;
}

export default function App() {
  const hydrated = useStoreHydrated();

  useEffect(() => {
    if (!hydrated) return;
    const lang = useGame.getState().settings.lang;
    if (i18n.language !== lang) void i18n.changeLanguage(lang);
  }, [hydrated]);

  useEffect(() => {
    if (!hydrated) return;
    const pause = () => useGame.getState().pause();
    const resume = () => useGame.getState().resume();

    if (Platform.OS === 'web' && typeof document !== 'undefined') {
      const handler = () => {
        if (document.hidden) pause();
        else resume();
      };
      document.addEventListener('visibilitychange', handler);
      return () => document.removeEventListener('visibilitychange', handler);
    }

    const sub = AppState.addEventListener('change', (state) => {
      if (state === 'active') resume();
      else pause();
    });
    return () => sub.remove();
  }, [hydrated]);

  if (!hydrated) {
    return <View style={{ flex: 1, backgroundColor: '#0a0a0a' }} />;
  }

  return (
    <I18nextProvider i18n={i18n}>
      <ThemeProvider>
        <Inner />
      </ThemeProvider>
    </I18nextProvider>
  );
}
