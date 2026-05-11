import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import {
  Modal,
  Platform,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import { serializeBoard } from '../../core/board';
import { useGame } from '../../game/store';
import type { ImportError } from '../../game/store';
import { useTheme } from '../theme/ThemeProvider';

type Props = { visible: boolean; onClose: () => void };

export function PuzzleIOPanel({ visible, onClose }: Props) {
  const { theme } = useTheme();
  const { t } = useTranslation();
  const initial = useGame((s) => s.initial);
  const importPuzzle = useGame((s) => s.importPuzzle);

  const [input, setInput] = useState('');
  const [error, setError] = useState<ImportError | null>(null);
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    if (!visible) {
      setInput('');
      setError(null);
      setCopied(false);
    }
  }, [visible]);

  const exported = serializeBoard(initial);

  const onImport = () => {
    const result = importPuzzle(input);
    if (result.ok) {
      onClose();
    } else {
      setError(result.error);
    }
  };

  const onCopy = async () => {
    if (
      Platform.OS === 'web' &&
      typeof navigator !== 'undefined' &&
      navigator.clipboard
    ) {
      try {
        await navigator.clipboard.writeText(exported);
        setCopied(true);
        setTimeout(() => setCopied(false), 1500);
        return;
      } catch {
        // fall through
      }
    }
    setCopied(true);
    setTimeout(() => setCopied(false), 1500);
  };

  return (
    <Modal
      visible={visible}
      transparent
      animationType="fade"
      onRequestClose={onClose}
    >
      <Pressable
        style={[styles.scrim, { backgroundColor: theme.scrim }]}
        onPress={onClose}
      >
        <Pressable
          onPress={(e) => e.stopPropagation()}
          style={[
            styles.box,
            { backgroundColor: theme.bgElevated, borderColor: theme.border },
          ]}
        >
          <Text style={[styles.title, { color: theme.text }]}>
            {t('io.title')}
          </Text>

          <View style={styles.section}>
            <Text style={[styles.sectionLabel, { color: theme.textMuted }]}>
              {t('io.import_label')}
            </Text>
            <TextInput
              value={input}
              onChangeText={(v) => {
                setInput(v);
                setError(null);
              }}
              placeholder={t('io.placeholder')}
              placeholderTextColor={theme.textMuted}
              autoCapitalize="none"
              autoCorrect={false}
              multiline
              style={[
                styles.field,
                {
                  color: theme.text,
                  backgroundColor: theme.bg,
                  borderColor: theme.border,
                },
              ]}
            />
            <View style={styles.rowBetween}>
              <Text
                style={[
                  styles.helper,
                  {
                    color:
                      error != null ? theme.textConflict : theme.textMuted,
                  },
                ]}
              >
                {error != null
                  ? t(`io.errors.${error}`)
                  : t('io.helper', { count: input.replace(/\s+/g, '').length })}
              </Text>
              <Pressable
                onPress={onImport}
                disabled={input.trim().length === 0}
                style={({ pressed }) => [
                  styles.primaryBtn,
                  {
                    backgroundColor: theme.accent,
                    opacity:
                      input.trim().length === 0 ? 0.4 : pressed ? 0.85 : 1,
                  },
                ]}
              >
                <Text style={styles.primaryBtnText}>
                  {t('io.import_button')}
                </Text>
              </Pressable>
            </View>
          </View>

          <View
            style={[styles.divider, { backgroundColor: theme.border }]}
          />

          <View style={styles.section}>
            <Text style={[styles.sectionLabel, { color: theme.textMuted }]}>
              {t('io.export_label')}
            </Text>
            <TextInput
              value={exported}
              editable={false}
              multiline
              selectTextOnFocus
              style={[
                styles.field,
                styles.fieldMono,
                {
                  color: theme.text,
                  backgroundColor: theme.bg,
                  borderColor: theme.border,
                },
              ]}
            />
            <View style={styles.rowEnd}>
              <Pressable
                onPress={onCopy}
                style={({ pressed }) => [
                  styles.secondaryBtn,
                  {
                    backgroundColor: pressed
                      ? theme.buttonBgActive
                      : theme.buttonBg,
                    borderColor: theme.border,
                  },
                ]}
              >
                <Text style={{ color: theme.text, fontSize: 13 }}>
                  {copied ? t('io.copied') : t('io.copy')}
                </Text>
              </Pressable>
            </View>
          </View>

          <Pressable
            onPress={onClose}
            style={({ pressed }) => [
              styles.closeBtn,
              {
                backgroundColor: pressed ? theme.buttonBgActive : theme.buttonBg,
                borderColor: theme.border,
              },
            ]}
          >
            <Text style={{ color: theme.text, fontSize: 14 }}>
              {t('io.close')}
            </Text>
          </Pressable>
        </Pressable>
      </Pressable>
    </Modal>
  );
}

const styles = StyleSheet.create({
  scrim: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
  },
  box: {
    width: '100%',
    maxWidth: 420,
    borderRadius: 12,
    borderWidth: 1,
    padding: 16,
    gap: 12,
  },
  title: { fontSize: 16, fontWeight: '600' },
  section: { gap: 8 },
  sectionLabel: { fontSize: 12 },
  field: {
    minHeight: 64,
    borderWidth: 1,
    borderRadius: 8,
    paddingHorizontal: 10,
    paddingVertical: 8,
    fontSize: 13,
    textAlignVertical: 'top',
  },
  fieldMono: {
    fontFamily: Platform.select({
      web: 'ui-monospace, SFMono-Regular, Menlo, monospace',
      default: 'monospace',
    }),
  },
  helper: { fontSize: 12, flex: 1 },
  divider: { height: 1, marginVertical: 4 },
  rowBetween: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  rowEnd: { flexDirection: 'row', justifyContent: 'flex-end' },
  primaryBtn: {
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 6,
  },
  primaryBtnText: { color: '#ffffff', fontSize: 13, fontWeight: '600' },
  secondaryBtn: {
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 6,
    borderWidth: 1,
  },
  closeBtn: {
    alignSelf: 'flex-end',
    paddingVertical: 8,
    paddingHorizontal: 14,
    borderRadius: 6,
    borderWidth: 1,
  },
});
