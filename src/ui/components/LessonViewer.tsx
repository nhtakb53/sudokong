import { useEffect, useMemo, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import {
  Modal,
  Pressable,
  StyleSheet,
  Text,
  useWindowDimensions,
  View,
} from 'react-native';
import { parseBoard } from '../../core/board';
import type { Board, Step } from '../../core/types';
import { type Lesson } from '../../learn/courses';
import { buildFrames, getTechniqueName } from '../../learn/animation';
import { nextStep } from '../../solver/solver';
import { useTheme } from '../theme/ThemeProvider';
import { LessonBoard } from './LessonBoard';

type Props = {
  visible: boolean;
  lesson: Lesson | null;
  lang: 'ko' | 'en';
  onClose: () => void;
};

const AUTOPLAY_MS = 3000;

export function LessonViewer({ visible, lesson, lang, onClose }: Props) {
  const { theme } = useTheme();
  const { t } = useTranslation();
  const { width, height } = useWindowDimensions();

  const [frameIndex, setFrameIndex] = useState(0);
  const [isPlaying, setIsPlaying] = useState(false);

  const prepared = useMemo(() => {
    if (!lesson?.example) return null;
    let board: Board;
    try {
      board = parseBoard(lesson.example);
    } catch {
      return null;
    }
    const step = nextStep(board);
    if (!step) return { board, step: null, frames: [] };
    return { board, step, frames: buildFrames(step) };
  }, [lesson]);

  useEffect(() => {
    setFrameIndex(0);
    setIsPlaying(false);
  }, [lesson]);

  const lastFrameRef = useRef(0);
  lastFrameRef.current = prepared?.frames.length ?? 0;

  useEffect(() => {
    if (!isPlaying) return;
    const id = setInterval(() => {
      setFrameIndex((i) => {
        const last = lastFrameRef.current - 1;
        if (i >= last) {
          setIsPlaying(false);
          return i;
        }
        return i + 1;
      });
    }, AUTOPLAY_MS);
    return () => clearInterval(id);
  }, [isPlaying]);

  if (!visible || !lesson) return null;

  const boardSize = Math.min(width - 80, height * 0.45, 420);

  const renderBody = () => {
    if (!prepared) {
      return (
        <Text style={[styles.body, { color: theme.textConflict }]}>
          {t('learn.lesson.no_example')}
        </Text>
      );
    }
    if (!prepared.step) {
      return (
        <Text style={[styles.body, { color: theme.textMuted }]}>
          {t('learn.lesson.no_step')}
        </Text>
      );
    }
    const frame = prepared.frames[frameIndex];
    const matchesTechnique =
      lesson.techniqueId == null ||
      lesson.techniqueId === prepared.step.technique;

    return (
      <>
        {!matchesTechnique && (
          <Text style={[styles.notice, { color: theme.textMuted, borderColor: theme.border }]}>
            {t('learn.lesson.mismatch', {
              actual: getTechniqueName(prepared.step.technique)[lang],
            })}
          </Text>
        )}
        <View style={{ alignItems: 'center' }}>
          <LessonBoard
            board={prepared.board}
            step={prepared.step}
            highlights={frame.highlights}
            showEliminations={frame.showEliminations}
            showPlacements={frame.showPlacements}
            size={boardSize}
          />
        </View>
        <View
          style={[
            styles.descBox,
            { backgroundColor: theme.bg, borderColor: theme.border },
          ]}
        >
          <Text style={[styles.body, { color: theme.text }]}>
            {frame.description[lang]}
          </Text>
        </View>
        <View style={styles.controls}>
          <Pressable
            onPress={() => {
              setIsPlaying(false);
              setFrameIndex((i) => Math.max(0, i - 1));
            }}
            disabled={frameIndex === 0}
            style={({ pressed }) => [
              styles.ctrl,
              {
                backgroundColor: pressed ? theme.buttonBgActive : theme.buttonBg,
                borderColor: theme.border,
                opacity: frameIndex === 0 ? 0.4 : 1,
              },
            ]}
          >
            <Text style={{ color: theme.text, fontSize: 14 }}>◀</Text>
          </Pressable>

          <Pressable
            onPress={() => {
              if (frameIndex >= prepared.frames.length - 1) {
                setFrameIndex(0);
                setIsPlaying(true);
              } else {
                setIsPlaying((p) => !p);
              }
            }}
            style={({ pressed }) => [
              styles.ctrlPlay,
              {
                backgroundColor: pressed ? theme.buttonBgActive : theme.accent,
              },
            ]}
          >
            <Text style={{ color: '#fff', fontSize: 14, fontWeight: '600' }}>
              {isPlaying
                ? t('learn.lesson.pause')
                : frameIndex >= prepared.frames.length - 1
                  ? t('learn.lesson.replay')
                  : t('learn.lesson.play')}
            </Text>
          </Pressable>

          <Pressable
            onPress={() => {
              setIsPlaying(false);
              setFrameIndex((i) =>
                Math.min(prepared.frames.length - 1, i + 1),
              );
            }}
            disabled={frameIndex >= prepared.frames.length - 1}
            style={({ pressed }) => [
              styles.ctrl,
              {
                backgroundColor: pressed ? theme.buttonBgActive : theme.buttonBg,
                borderColor: theme.border,
                opacity: frameIndex >= prepared.frames.length - 1 ? 0.4 : 1,
              },
            ]}
          >
            <Text style={{ color: theme.text, fontSize: 14 }}>▶</Text>
          </Pressable>

          <Text style={[styles.progress, { color: theme.textMuted }]}>
            {frameIndex + 1} / {prepared.frames.length}
          </Text>
        </View>
      </>
    );
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
          <View style={styles.header}>
            <Text style={[styles.title, { color: theme.text }]}>
              {lesson.title[lang]}
            </Text>
            <Pressable
              onPress={onClose}
              style={({ pressed }) => [
                styles.closeIcon,
                {
                  backgroundColor: pressed
                    ? theme.buttonBgActive
                    : theme.buttonBg,
                  borderColor: theme.border,
                },
              ]}
            >
              <Text style={{ color: theme.text, fontSize: 13 }}>×</Text>
            </Pressable>
          </View>
          {renderBody()}
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
    padding: 16,
  },
  box: {
    width: '100%',
    maxWidth: 520,
    borderRadius: 12,
    borderWidth: 1,
    padding: 16,
    gap: 12,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  title: { fontSize: 16, fontWeight: '600', flex: 1 },
  closeIcon: {
    width: 28,
    height: 28,
    borderRadius: 14,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  notice: {
    fontSize: 12,
    padding: 8,
    borderRadius: 6,
    borderWidth: 1,
  },
  descBox: {
    padding: 12,
    borderRadius: 10,
    borderWidth: 1,
    minHeight: 64,
  },
  body: { fontSize: 14, lineHeight: 20 },
  controls: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
  },
  ctrl: {
    width: 44,
    height: 36,
    borderRadius: 6,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  ctrlPlay: {
    paddingHorizontal: 16,
    height: 36,
    borderRadius: 6,
    alignItems: 'center',
    justifyContent: 'center',
    minWidth: 100,
  },
  progress: { fontSize: 12, marginLeft: 8 },
});
