import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { useGame } from '../../game/store';
import { COURSES, type Lesson } from '../../learn/courses';
import { useTheme } from '../theme/ThemeProvider';
import { CourseDetail, CourseList, type Lang } from './LearnPanel';
import { LessonViewer } from './LessonViewer';

export function LearnSidebar() {
  const { theme } = useTheme();
  const { t, i18n } = useTranslation();
  const importPuzzle = useGame((s) => s.importPuzzle);
  const [activeCourseId, setActiveCourseId] = useState<string | null>(null);
  const [viewerLesson, setViewerLesson] = useState<Lesson | null>(null);

  const lang: Lang = (i18n.language === 'ko' ? 'ko' : 'en') as Lang;
  const activeCourse = COURSES.find((c) => c.id === activeCourseId) ?? null;

  const handleStartExample = (lesson: Lesson) => {
    if (!lesson.example) return;
    importPuzzle(lesson.example);
  };

  return (
    <View
      style={[
        styles.root,
        {
          backgroundColor: theme.bgElevated,
          borderRightColor: theme.border,
        },
      ]}
    >
      <View style={styles.header}>
        {activeCourse ? (
          <Pressable
            onPress={() => setActiveCourseId(null)}
            style={({ pressed }) => [
              styles.backBtn,
              {
                backgroundColor: pressed ? theme.buttonBgActive : theme.buttonBg,
                borderColor: theme.border,
              },
            ]}
          >
            <Text style={{ color: theme.text, fontSize: 13 }}>
              {t('learn.back')}
            </Text>
          </Pressable>
        ) : null}
        <Text style={[styles.title, { color: theme.text }]}>
          {activeCourse ? activeCourse.title[lang] : t('learn.title')}
        </Text>
      </View>

      <ScrollView
        style={{ flex: 1 }}
        contentContainerStyle={styles.content}
      >
        {activeCourse ? (
          <CourseDetail
            course={activeCourse}
            lang={lang}
            onStartExample={handleStartExample}
            onOpenLesson={(l) => setViewerLesson(l)}
          />
        ) : (
          <CourseList lang={lang} onSelect={setActiveCourseId} />
        )}
      </ScrollView>

      <LessonViewer
        visible={viewerLesson != null}
        lesson={viewerLesson}
        lang={lang}
        onClose={() => setViewerLesson(null)}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    paddingHorizontal: 12,
    paddingVertical: 16,
    paddingTop: 48,
    borderRightWidth: 1,
    gap: 12,
  },
  header: { gap: 8 },
  title: { fontSize: 18, fontWeight: '700' },
  backBtn: {
    alignSelf: 'flex-start',
    paddingVertical: 6,
    paddingHorizontal: 10,
    borderRadius: 6,
    borderWidth: 1,
  },
  content: { gap: 10, paddingBottom: 24 },
});
