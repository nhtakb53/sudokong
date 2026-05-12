import type { Highlight, Step } from '../core/types';
import type { LocalizedText } from './courses';

export type AnimationFrame = {
  description: LocalizedText;
  highlights: Highlight;
  showEliminations: boolean;
  showPlacements: boolean;
};

const T = (ko: string, en: string): LocalizedText => ({ ko, en });

const TECH_NAME: Record<string, LocalizedText> = {
  naked_single: T('단일 후보', 'Naked Single'),
  hidden_single: T('숨은 단일', 'Hidden Single'),
  locked_candidates_pointing: T('포인팅', 'Pointing'),
  locked_candidates_claiming: T('클레이밍', 'Claiming'),
  naked_pair: T('노출 페어', 'Naked Pair'),
  hidden_pair: T('숨은 페어', 'Hidden Pair'),
  naked_triple: T('노출 트리플', 'Naked Triple'),
  hidden_triple: T('숨은 트리플', 'Hidden Triple'),
  naked_quad: T('노출 쿼드', 'Naked Quad'),
  hidden_quad: T('숨은 쿼드', 'Hidden Quad'),
  x_wing: T('엑스윙', 'X-Wing'),
};

export function getTechniqueName(id: string): LocalizedText {
  return TECH_NAME[id] ?? T(id, id);
}

export function buildFrames(step: Step): AnimationFrame[] {
  const frames: AnimationFrame[] = [];
  const name = getTechniqueName(step.technique);

  frames.push({
    description: T(
      '먼저 보드 전체의 후보를 살펴봅시다. 빈 칸마다 가능한 숫자가 작게 표시돼 있어요.',
      'First, look at all candidates on the board. Each empty cell shows the digits that could go there.',
    ),
    highlights: {},
    showEliminations: false,
    showPlacements: false,
  });

  if (step.highlights.units && step.highlights.units.length > 0) {
    frames.push({
      description: T(
        '이 영역(행/열/박스)에 주목하세요. 패턴이 이곳에서 발생합니다.',
        'Focus on this region (row/column/box). The pattern lives here.',
      ),
      highlights: { units: step.highlights.units },
      showEliminations: false,
      showPlacements: false,
    });
  }

  if (step.highlights.cells && step.highlights.cells.length > 0) {
    frames.push({
      description: T(
        '이 셀들이 패턴의 핵심입니다. 색깔이 다른 셀은 역할이 다릅니다.',
        'These cells form the heart of the pattern. Different colors mean different roles.',
      ),
      highlights: {
        units: step.highlights.units,
        cells: step.highlights.cells,
      },
      showEliminations: false,
      showPlacements: false,
    });
  }

  frames.push({
    description: T(
      `[${name.ko}] 이 패턴이 맞다면, 위 셀들의 후보 배치는 강하게 제약됩니다.`,
      `[${name.en}] Given this pattern, the candidates in those cells are tightly constrained.`,
    ),
    highlights: step.highlights,
    showEliminations: false,
    showPlacements: false,
  });

  if (step.eliminations.length > 0) {
    frames.push({
      description: T(
        '그래서 다음 후보들을 제거할 수 있습니다 (× 표시).',
        'So we can eliminate these candidates (marked with ×).',
      ),
      highlights: step.highlights,
      showEliminations: true,
      showPlacements: false,
    });
  }

  if (step.placements.length > 0) {
    frames.push({
      description: T(
        '결과: 이 칸에 답이 들어갑니다.',
        'Result: these cells are filled in.',
      ),
      highlights: step.highlights,
      showEliminations: true,
      showPlacements: true,
    });
  } else {
    frames.push({
      description: T(
        '제거된 후보 덕분에 이후 다른 기법으로 진전할 수 있게 됩니다.',
        'These eliminations open the door to further techniques.',
      ),
      highlights: step.highlights,
      showEliminations: true,
      showPlacements: false,
    });
  }

  return frames;
}
