import { useTranslation } from 'react-i18next';
import { Modal, Pressable, StyleSheet, Text, View } from 'react-native';
import { useGame } from '../../game/store';
import type { FontScale } from '../../game/store';
import { useTheme } from '../theme/ThemeProvider';

type Props = { visible: boolean; onClose: () => void };

const FONT_SCALES: FontScale[] = ['sm', 'md', 'lg'];

export function SettingsPanel({ visible, onClose }: Props) {
  const { theme } = useTheme();
  const { t } = useTranslation();
  const settings = useGame((s) => s.settings);
  const setSetting = useGame((s) => s.setSetting);

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
            {t('settings.title')}
          </Text>

          <ToggleRow
            label={t('settings.highlight_same_digit')}
            value={settings.highlightSameDigit}
            onToggle={() =>
              setSetting('highlightSameDigit', !settings.highlightSameDigit)
            }
          />
          <ToggleRow
            label={t('settings.highlight_peers')}
            value={settings.highlightPeers}
            onToggle={() => setSetting('highlightPeers', !settings.highlightPeers)}
          />
          <ToggleRow
            label={t('settings.color_blind')}
            value={settings.colorBlind}
            onToggle={() => setSetting('colorBlind', !settings.colorBlind)}
          />

          <View style={styles.section}>
            <Text style={[styles.sectionLabel, { color: theme.textMuted }]}>
              {t('settings.font_scale')}
            </Text>
            <View style={styles.segments}>
              {FONT_SCALES.map((s) => {
                const active = settings.fontScale === s;
                return (
                  <Pressable
                    key={s}
                    onPress={() => setSetting('fontScale', s)}
                    style={({ pressed }) => [
                      styles.segment,
                      {
                        backgroundColor: active
                          ? theme.buttonBgActive
                          : pressed
                            ? theme.buttonBgActive
                            : theme.buttonBg,
                        borderColor: theme.border,
                      },
                    ]}
                  >
                    <Text style={{ color: theme.text, fontSize: 13 }}>
                      {t(`settings.font_${s}`)}
                    </Text>
                  </Pressable>
                );
              })}
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
              {t('settings.close')}
            </Text>
          </Pressable>
        </Pressable>
      </Pressable>
    </Modal>
  );
}

function ToggleRow({
  label,
  value,
  onToggle,
}: {
  label: string;
  value: boolean;
  onToggle: () => void;
}) {
  const { theme } = useTheme();
  return (
    <Pressable onPress={onToggle} style={styles.toggleRow}>
      <Text style={{ color: theme.text, fontSize: 14, flex: 1 }}>{label}</Text>
      <View
        style={[
          styles.switchTrack,
          { backgroundColor: value ? theme.accent : theme.buttonBg, borderColor: theme.border },
        ]}
      >
        <View
          style={[
            styles.switchThumb,
            {
              backgroundColor: '#ffffff',
              transform: [{ translateX: value ? 18 : 0 }],
            },
          ]}
        />
      </View>
    </Pressable>
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
    maxWidth: 380,
    borderRadius: 12,
    borderWidth: 1,
    padding: 16,
    gap: 12,
  },
  title: { fontSize: 16, fontWeight: '600' },
  toggleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 6,
    gap: 12,
  },
  switchTrack: {
    width: 42,
    height: 24,
    borderRadius: 12,
    borderWidth: 1,
    padding: 2,
    justifyContent: 'center',
  },
  switchThumb: {
    width: 18,
    height: 18,
    borderRadius: 9,
  },
  section: { gap: 6, marginTop: 4 },
  sectionLabel: { fontSize: 12 },
  segments: { flexDirection: 'row', gap: 6 },
  segment: {
    flex: 1,
    paddingVertical: 8,
    borderRadius: 8,
    borderWidth: 1,
    alignItems: 'center',
  },
  closeBtn: {
    alignSelf: 'flex-end',
    paddingVertical: 8,
    paddingHorizontal: 14,
    borderRadius: 6,
    borderWidth: 1,
    marginTop: 4,
  },
});
