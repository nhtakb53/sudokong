import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Pressable, StyleSheet, Text, useWindowDimensions, View } from 'react-native';
import type { Lang } from '../../game/store';
import { useGame } from '../../game/store';
import { useTheme } from '../theme/ThemeProvider';
import { ConfirmDialog } from './ConfirmDialog';
import { LearnPanel } from './LearnPanel';
import { PuzzleIOPanel } from './PuzzleIOPanel';
import { SettingsPanel } from './SettingsPanel';

export function Toolbar() {
  const { theme, toggle: toggleTheme } = useTheme();
  const { t, i18n } = useTranslation();
  const autoPencil = useGame((s) => s.autoPencil);
  const toggleAutoPencil = useGame((s) => s.toggleAutoPencil);
  const erase = useGame((s) => s.erase);
  const undo = useGame((s) => s.undo);
  const redo = useGame((s) => s.redo);
  const newGame = useGame((s) => s.newGame);
  const requestHint = useGame((s) => s.requestHint);
  const setSetting = useGame((s) => s.setSetting);
  const validate = useGame((s) => s.validate);
  const validateActive = useGame((s) => s.validateActive);
  const fillAllCandidates = useGame((s) => s.fillAllCandidates);
  const initial = useGame((s) => s.initial);
  const current = useGame((s) => s.current);
  const completedAt = useGame((s) => s.completedAt);
  const canUndo = useGame((s) => s.historyIndex > 0);
  const canRedo = useGame((s) => s.historyIndex < s.history.length - 1);
  const eraseDisabled = useGame((s) => {
    if (!s.selectedCell) return true;
    const { r, c } = s.selectedCell;
    if (s.initial[r][c] !== 0) return true;
    return s.current[r][c] === 0 && s.pencils[r][c] === 0;
  });

  const [confirmOpen, setConfirmOpen] = useState(false);
  const [settingsOpen, setSettingsOpen] = useState(false);
  const [ioOpen, setIoOpen] = useState(false);
  const [learnOpen, setLearnOpen] = useState(false);
  const { width } = useWindowDimensions();
  const showLearnButton = width < 768;

  const hasProgress =
    completedAt == null &&
    current.some((row, r) =>
      row.some((v, c) => v !== 0 && initial[r][c] === 0),
    );

  const onNewGame = () => {
    if (hasProgress) {
      setConfirmOpen(true);
    } else {
      newGame();
    }
  };

  const buttons = [
    {
      key: 'autopencil',
      label: t('play.actions.auto_pencil'),
      onPress: toggleAutoPencil,
      active: autoPencil,
    },
    {
      key: 'fillcands',
      label: t('play.actions.fill_candidates'),
      onPress: fillAllCandidates,
    },
    { key: 'hint', label: t('play.actions.hint'), onPress: requestHint },
    ...(showLearnButton
      ? [
          {
            key: 'learn',
            label: t('play.actions.learn'),
            onPress: () => setLearnOpen(true),
          },
        ]
      : []),
    {
      key: 'validate',
      label: t('play.actions.validate'),
      onPress: validate,
      active: validateActive,
    },
    {
      key: 'erase',
      label: t('play.actions.erase'),
      onPress: erase,
      disabled: eraseDisabled,
    },
    {
      key: 'undo',
      label: t('play.actions.undo'),
      onPress: undo,
      disabled: !canUndo,
    },
    {
      key: 'redo',
      label: t('play.actions.redo'),
      onPress: redo,
      disabled: !canRedo,
    },
    { key: 'new', label: t('play.actions.new'), onPress: onNewGame },
    {
      key: 'puzzle',
      label: t('play.actions.puzzle_io'),
      onPress: () => setIoOpen(true),
    },
    {
      key: 'settings',
      label: t('play.actions.settings'),
      onPress: () => setSettingsOpen(true),
    },
    { key: 'theme', label: t('play.actions.theme'), onPress: toggleTheme },
    {
      key: 'lang',
      label: t('play.actions.lang'),
      onPress: () => {
        const next: Lang = i18n.language === 'ko' ? 'en' : 'ko';
        void i18n.changeLanguage(next);
        setSetting('lang', next);
      },
    },
  ];

  return (
    <>
      <View style={styles.row}>
        {buttons.map((b) => {
          const disabled = b.disabled === true;
          return (
            <Pressable
              key={b.key}
              onPress={b.onPress}
              disabled={disabled}
              style={({ pressed }) => [
                styles.btn,
                {
                  backgroundColor: b.active
                    ? theme.buttonBgActive
                    : pressed && !disabled
                      ? theme.buttonBgActive
                      : theme.buttonBg,
                  borderColor: theme.border,
                  opacity: disabled ? 0.4 : 1,
                },
              ]}
            >
              <Text style={[styles.label, { color: theme.text }]}>{b.label}</Text>
            </Pressable>
          );
        })}
      </View>

      <ConfirmDialog
        visible={confirmOpen}
        title={t('play.confirm.new_game_title')}
        message={t('play.confirm.new_game_message')}
        confirmLabel={t('play.confirm.confirm')}
        cancelLabel={t('play.confirm.cancel')}
        onConfirm={() => {
          setConfirmOpen(false);
          newGame();
        }}
        onCancel={() => setConfirmOpen(false)}
      />

      <SettingsPanel
        visible={settingsOpen}
        onClose={() => setSettingsOpen(false)}
      />

      <PuzzleIOPanel visible={ioOpen} onClose={() => setIoOpen(false)} />

      <LearnPanel visible={learnOpen} onClose={() => setLearnOpen(false)} />
    </>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: 'row', flexWrap: 'wrap', gap: 6 },
  btn: {
    paddingVertical: 8,
    paddingHorizontal: 12,
    borderRadius: 8,
    borderWidth: 1,
  },
  label: { fontSize: 14 },
});
