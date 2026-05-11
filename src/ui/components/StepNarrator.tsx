import { useTranslation } from 'react-i18next';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { useGame } from '../../game/store';
import { useTheme } from '../theme/ThemeProvider';

export function StepNarrator() {
  const hint = useGame((s) => s.hint);
  const clearHint = useGame((s) => s.clearHint);
  const applyHint = useGame((s) => s.applyHint);
  const { theme } = useTheme();
  const { t } = useTranslation();

  if (!hint) return null;

  const techName = t(`techniques.${hint.technique}.name`);
  const params = { ...(hint.explanationParams ?? {}) };
  // i18next can't join arrays — flatten array params to a comma string
  for (const k of Object.keys(params)) {
    const v = (params as Record<string, unknown>)[k];
    if (Array.isArray(v)) {
      (params as Record<string, unknown>)[k] = v.join(', ');
    }
  }
  const explanation = t(hint.explanationKey, params);

  return (
    <View
      style={[
        styles.box,
        { backgroundColor: theme.bgElevated, borderColor: theme.border },
      ]}
    >
      <Text style={[styles.title, { color: theme.text }]}>{techName}</Text>
      <Text style={[styles.body, { color: theme.textMuted }]}>
        {explanation}
      </Text>
      <View style={styles.row}>
        <Pressable
          onPress={applyHint}
          style={({ pressed }) => [
            styles.btn,
            {
              backgroundColor: theme.accent,
              opacity: pressed ? 0.85 : 1,
            },
          ]}
        >
          <Text style={[styles.btnText, { color: '#ffffff' }]}>
            {t('play.actions.apply_hint')}
          </Text>
        </Pressable>
        <Pressable
          onPress={clearHint}
          style={({ pressed }) => [
            styles.btn,
            {
              backgroundColor: pressed ? theme.buttonBgActive : theme.buttonBg,
              borderColor: theme.border,
              borderWidth: 1,
            },
          ]}
        >
          <Text style={[styles.btnText, { color: theme.text }]}>
            {t('play.actions.dismiss')}
          </Text>
        </Pressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  box: {
    padding: 12,
    borderRadius: 10,
    borderWidth: 1,
    gap: 8,
  },
  title: { fontSize: 14, fontWeight: '600' },
  body: { fontSize: 13, lineHeight: 18 },
  row: { flexDirection: 'row', gap: 8 },
  btn: {
    paddingHorizontal: 14,
    paddingVertical: 7,
    borderRadius: 6,
  },
  btnText: { fontSize: 13, fontWeight: '500' },
});
