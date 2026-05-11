import { Modal, Pressable, StyleSheet, Text, View } from 'react-native';
import { useTheme } from '../theme/ThemeProvider';

type Props = {
  visible: boolean;
  title: string;
  message?: string;
  confirmLabel: string;
  cancelLabel: string;
  onConfirm: () => void;
  onCancel: () => void;
};

export function ConfirmDialog({
  visible,
  title,
  message,
  confirmLabel,
  cancelLabel,
  onConfirm,
  onCancel,
}: Props) {
  const { theme } = useTheme();
  return (
    <Modal
      visible={visible}
      transparent
      animationType="fade"
      onRequestClose={onCancel}
    >
      <Pressable
        style={[styles.scrim, { backgroundColor: theme.scrim }]}
        onPress={onCancel}
      >
        <Pressable
          onPress={(e) => e.stopPropagation()}
          style={[
            styles.box,
            { backgroundColor: theme.bgElevated, borderColor: theme.border },
          ]}
        >
          <Text style={[styles.title, { color: theme.text }]}>{title}</Text>
          {message ? (
            <Text style={[styles.body, { color: theme.textMuted }]}>
              {message}
            </Text>
          ) : null}
          <View style={styles.row}>
            <Pressable
              onPress={onCancel}
              style={({ pressed }) => [
                styles.btn,
                {
                  backgroundColor: pressed ? theme.buttonBgActive : theme.buttonBg,
                  borderColor: theme.border,
                  borderWidth: 1,
                },
              ]}
            >
              <Text style={{ color: theme.text, fontSize: 14 }}>
                {cancelLabel}
              </Text>
            </Pressable>
            <Pressable
              onPress={onConfirm}
              style={({ pressed }) => [
                styles.btn,
                {
                  backgroundColor: theme.accent,
                  opacity: pressed ? 0.85 : 1,
                },
              ]}
            >
              <Text style={{ color: '#ffffff', fontSize: 14, fontWeight: '600' }}>
                {confirmLabel}
              </Text>
            </Pressable>
          </View>
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
    maxWidth: 360,
    borderRadius: 12,
    borderWidth: 1,
    padding: 16,
    gap: 10,
  },
  title: { fontSize: 16, fontWeight: '600' },
  body: { fontSize: 13, lineHeight: 18 },
  row: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: 8,
    marginTop: 4,
  },
  btn: {
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 6,
  },
});
