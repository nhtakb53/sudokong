import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import {
  Modal,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { useGame } from '../../game/store';
import { COURSES, type Course, type Lesson } from '../../learn/courses';
import { useTheme } from '../theme/ThemeProvider';
import { LessonViewer } from './LessonViewer';

type Props = { visible: boolean; onClose: () => void };

export type Lang = 'ko' | 'en';

export function LearnPanel({ visible, onClose }: Props) {
  const { theme } = useTheme();
  const { i18n, t } = useTranslation();
  const importPuzzle = useGame((s) => s.importPuzzle);
  const [activeCourseId, setActiveCourseId] = useState<string | null>(null);
  const [viewerLesson, setViewerLesson] = useState<Lesson | null>(null);

  const lang: Lang = (i18n.language === 'ko' ? 'ko' : 'en') as Lang;
  const activeCourse = COURSES.find((c) => c.id === activeCourseId) ?? null;

  const handleClose = () => {
    setActiveCourseId(null);
    setViewerLesson(null);
    onClose();
  };

  const handleStartExample = (lesson: Lesson) => {
    if (!lesson.example) return;
    const result = importPuzzle(lesson.example);
    if (result.ok) {
      handleClose();
    }
  };

  return (
    <>
      <Modal
        visible={visible}
        transparent
        animationType="fade"
        onRequestClose={handleClose}
      >
        <Pressable
          style={[styles.scrim, { backgroundColor: theme.scrim }]}
          onPress={handleClose}
        >
          <Pressable
            onPress={(e) => e.stopPropagation()}
            style={[
              styles.box,
              { backgroundColor: theme.bgElevated, borderColor: theme.border },
            ]}
          >
            <View style={styles.header}>
              {activeCourse ? (
                <Pressable
                  onPress={() => setActiveCourseId(null)}
                  style={({ pressed }) => [
                    styles.backBtn,
                    {
                      backgroundColor: pressed
                        ? theme.buttonBgActive
                        : theme.buttonBg,
                      borderColor: theme.border,
                    },
                  ]}
                >
                  <Text style={{ color: theme.text, fontSize: 13 }}>
                    {t('learn.back')}
                  </Text>
                </Pressable>
              ) : (
                <View style={{ width: 60 }} />
              )}
              <Text style={[styles.title, { color: theme.text }]}>
                {activeCourse ? activeCourse.title[lang] : t('learn.title')}
              </Text>
              <Pressable
                onPress={handleClose}
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

            <ScrollView style={{ maxHeight: 520 }}>
              {activeCourse ? (
                <CourseDetail
                  course={activeCourse}
                  lang={lang}
                  onStartExample={handleStartExample}
                  onOpenLesson={(l) => setViewerLesson(l)}
                />
              ) : (
                <CourseList
                  lang={lang}
                  onSelect={(id) => setActiveCourseId(id)}
                />
              )}
            </ScrollView>
          </Pressable>
        </Pressable>
      </Modal>

      <LessonViewer
        visible={viewerLesson != null}
        lesson={viewerLesson}
        lang={lang}
        onClose={() => setViewerLesson(null)}
      />
    </>
  );
}

export function CourseList({
  lang,
  onSelect,
}: {
  lang: Lang;
  onSelect: (id: string) => void;
}) {
  const { theme } = useTheme();
  const { t } = useTranslation();

  return (
    <View style={styles.list}>
      {COURSES.map((c) => {
        const total = c.lessons.length;
        const ready = c.lessons.filter((l) => l.status === 'available').length;
        return (
          <Pressable
            key={c.id}
            onPress={() => onSelect(c.id)}
            style={({ pressed }) => [
              styles.courseCard,
              {
                backgroundColor: pressed ? theme.buttonBgActive : theme.bg,
                borderColor: theme.border,
              },
            ]}
          >
            <View style={styles.courseHeader}>
              <Text style={[styles.courseTitle, { color: theme.text }]}>
                {c.title[lang]}
              </Text>
              <Text style={[styles.lessonMeta, { color: theme.textMuted }]}>
                {ready === total
                  ? t('learn.lessons_ready', { ready, total })
                  : ready === 0
                    ? t('learn.coming_soon')
                    : t('learn.lessons_partial', { ready, total })}
              </Text>
            </View>
            <Text style={[styles.courseDesc, { color: theme.textMuted }]}>
              {c.desc[lang]}
            </Text>
          </Pressable>
        );
      })}
    </View>
  );
}

export function CourseDetail({
  course,
  lang,
  onStartExample,
  onOpenLesson,
}: {
  course: Course;
  lang: Lang;
  onStartExample: (lesson: Lesson) => void;
  onOpenLesson: (lesson: Lesson) => void;
}) {
  const { theme } = useTheme();
  const { t } = useTranslation();

  return (
    <View style={styles.list}>
      <Text style={[styles.courseDesc, { color: theme.textMuted }]}>
        {course.desc[lang]}
      </Text>
      {course.lessons.map((lesson) => {
        const available = lesson.status === 'available';
        return (
          <View
            key={lesson.id}
            style={[
              styles.lessonCard,
              {
                backgroundColor: theme.bg,
                borderColor: theme.border,
                opacity: available ? 1 : 0.55,
              },
            ]}
          >
            <View style={styles.lessonHeader}>
              <Text style={[styles.lessonTitle, { color: theme.text }]}>
                {lesson.title[lang]}
              </Text>
              {!available && (
                <Text
                  style={[
                    styles.badge,
                    { color: theme.textMuted, borderColor: theme.border },
                  ]}
                >
                  {t('learn.coming_soon')}
                </Text>
              )}
            </View>
            <Text style={[styles.lessonDesc, { color: theme.textMuted }]}>
              {lesson.desc[lang]}
            </Text>
            {available && lesson.example ? (
              <View style={styles.lessonBtnRow}>
                <Pressable
                  onPress={() => onOpenLesson(lesson)}
                  style={({ pressed }) => [
                    styles.primaryBtn,
                    {
                      backgroundColor: theme.accent,
                      opacity: pressed ? 0.85 : 1,
                    },
                  ]}
                >
                  <Text style={styles.primaryBtnText}>
                    {t('learn.visual_lesson')}
                  </Text>
                </Pressable>
                <Pressable
                  onPress={() => onStartExample(lesson)}
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
                    {t('learn.start_example')}
                  </Text>
                </Pressable>
              </View>
            ) : null}
          </View>
        );
      })}
    </View>
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
    maxWidth: 560,
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
  title: { fontSize: 16, fontWeight: '600', flex: 1, textAlign: 'center' },
  backBtn: {
    paddingVertical: 6,
    paddingHorizontal: 10,
    borderRadius: 6,
    borderWidth: 1,
    width: 60,
    alignItems: 'center',
  },
  closeIcon: {
    width: 28,
    height: 28,
    borderRadius: 14,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  list: { gap: 10, paddingVertical: 4 },
  courseCard: {
    padding: 12,
    borderRadius: 10,
    borderWidth: 1,
    gap: 6,
  },
  courseHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    gap: 8,
  },
  courseTitle: { fontSize: 15, fontWeight: '600', flex: 1 },
  courseDesc: { fontSize: 13, lineHeight: 18 },
  lessonMeta: { fontSize: 11 },
  lessonCard: {
    padding: 12,
    borderRadius: 10,
    borderWidth: 1,
    gap: 8,
  },
  lessonHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  lessonTitle: { fontSize: 14, fontWeight: '600', flex: 1 },
  badge: {
    fontSize: 11,
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
    borderWidth: 1,
  },
  lessonDesc: { fontSize: 13, lineHeight: 18 },
  lessonBtnRow: { flexDirection: 'row', gap: 8, flexWrap: 'wrap' },
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
});
