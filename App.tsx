import { StatusBar } from 'expo-status-bar';
import { I18nextProvider } from 'react-i18next';
import { View } from 'react-native';
import i18n from './src/i18n';
import { PlayScreen } from './src/ui/screens/PlayScreen';
import { ThemeProvider, useTheme } from './src/ui/theme/ThemeProvider';

function Inner() {
  const { theme, isDark } = useTheme();
  return (
    <View style={{ flex: 1, backgroundColor: theme.bg }}>
      <PlayScreen />
      <StatusBar style={isDark ? 'light' : 'dark'} />
    </View>
  );
}

export default function App() {
  return (
    <I18nextProvider i18n={i18n}>
      <ThemeProvider>
        <Inner />
      </ThemeProvider>
    </I18nextProvider>
  );
}
