import { PUZZLES } from '../data/samplePuzzles';

export type LessonStatus = 'available' | 'coming_soon';

export type LocalizedText = { ko: string; en: string };

export type Lesson = {
  id: string;
  techniqueId?: string;
  title: LocalizedText;
  desc: LocalizedText;
  example?: string;
  status: LessonStatus;
};

export type Course = {
  id: string;
  level: number;
  title: LocalizedText;
  desc: LocalizedText;
  lessons: Lesson[];
};

const t = (ko: string, en: string): LocalizedText => ({ ko, en });

export const COURSES: Course[] = [
  {
    id: 'singles',
    level: 0,
    title: t('1. 기초 셀', '1. Singles'),
    desc: t(
      '한 칸 또는 한 유닛에서 답이 즉시 결정되는 가장 기본 패턴.',
      'Cells or units where the answer is immediately forced.',
    ),
    lessons: [
      {
        id: 'naked_single',
        techniqueId: 'naked_single',
        title: t('단일 후보 (Naked Single)', 'Naked Single'),
        desc: t(
          '한 칸에 들어갈 수 있는 후보가 단 하나만 남으면 그 숫자가 답입니다. 가장 기본적인 패턴이에요.',
          'When a cell has only one candidate left, that digit is the answer. The most fundamental pattern.',
        ),
        example: PUZZLES.EASY,
        status: 'available',
      },
      {
        id: 'hidden_single',
        techniqueId: 'hidden_single',
        title: t('숨은 단일 (Hidden Single)', 'Hidden Single'),
        desc: t(
          '한 행/열/박스에서 어떤 숫자가 들어갈 수 있는 칸이 한 곳뿐이면, 다른 후보들이 있어도 그 자리가 답입니다.',
          'When a digit can only be placed in one cell within a row/column/box, that cell is the answer even if it has other candidates.',
        ),
        example:
          '4.27.6...........656..1..7.....5.21.1.......8.87.9.....3..7..658...........9.84.1',
        status: 'available',
      },
    ],
  },
  {
    id: 'subsets',
    level: 1,
    title: t('2. 부분집합 (Subsets)', '2. Subsets'),
    desc: t(
      '여러 칸이 후보를 공유하는 패턴. 같은 유닛의 다른 칸에서 그 후보를 제거합니다.',
      'Cells sharing candidates within a unit, letting us eliminate those candidates elsewhere.',
    ),
    lessons: [
      {
        id: 'naked_pair',
        techniqueId: 'naked_pair',
        title: t('노출 페어 (Naked Pair)', 'Naked Pair'),
        desc: t(
          '한 유닛 안 두 칸이 정확히 같은 후보 두 개만 가지면, 그 두 숫자는 반드시 그 두 칸에 들어갑니다. 같은 유닛의 다른 칸에서 두 후보를 모두 제거할 수 있습니다.',
          'If two cells in a unit hold exactly the same two candidates, those digits must occupy those cells — eliminate them from the rest of the unit.',
        ),
        example:
          '76284913513.756.8.58.123...61593472.24761.358398257614.732658.1..1.78...8.6.91...',
        status: 'available',
      },
      {
        id: 'hidden_pair',
        techniqueId: 'hidden_pair',
        title: t('숨은 페어 (Hidden Pair)', 'Hidden Pair'),
        desc: t(
          '한 유닛에서 두 숫자가 같은 두 칸에만 등장하면, 그 두 칸의 다른 후보는 모두 제거할 수 있습니다.',
          'If two digits appear only in the same two cells of a unit, all other candidates in those cells can be removed.',
        ),
        example:
          '72.4.8.3..8.....474.1.768.281.739......851......264.8.2.968.41334......8168943275',
        status: 'available',
      },
      {
        id: 'naked_triple',
        techniqueId: 'naked_triple',
        title: t('노출 트리플 (Naked Triple)', 'Naked Triple'),
        desc: t(
          '세 칸의 후보 합집합이 정확히 세 개. 페어의 확장입니다.',
          'Three cells whose candidates union to exactly three digits — a pair, extended.',
        ),
        example: PUZZLES.MEDIUM,
        status: 'available',
      },
      {
        id: 'hidden_triple',
        techniqueId: 'hidden_triple',
        title: t('숨은 트리플 (Hidden Triple)', 'Hidden Triple'),
        desc: t(
          '세 숫자가 같은 세 칸에만 등장합니다.',
          'Three digits appearing only in the same three cells.',
        ),
        example:
          '28....473534827196.71.34.8.3..5...4....34..6.46.79.31..9.2.3654..3..9821....8.937',
        status: 'available',
      },
      {
        id: 'naked_quad',
        techniqueId: 'naked_quad',
        title: t('노출 쿼드 (Naked Quad)', 'Naked Quad'),
        desc: t('네 칸 네 후보.', 'Four cells, four candidates.'),
        example:
          '.1.72.563.56.3.247732546189693287415247615938581394........2...........1..587....',
        status: 'available',
      },
      {
        id: 'hidden_quad',
        techniqueId: 'hidden_quad',
        title: t('숨은 쿼드 (Hidden Quad)', 'Hidden Quad'),
        desc: t('네 숫자가 같은 네 칸에만.', 'Four digits in only four cells.'),
        example: PUZZLES.HARD,
        status: 'available',
      },
    ],
  },
  {
    id: 'locked_candidates',
    level: 1,
    title: t('3. 박스와 라인 (Locked Candidates)', '3. Locked Candidates'),
    desc: t(
      '한 숫자가 박스와 행/열의 교차에 갇혀 있을 때 외부 후보를 제거.',
      'A digit confined to a box-line intersection lets us eliminate it outside.',
    ),
    lessons: [
      {
        id: 'pointing',
        techniqueId: 'locked_candidates_pointing',
        title: t('포인팅 (Pointing)', 'Pointing'),
        desc: t(
          '한 박스 안에서 어떤 숫자가 단 한 행(또는 열)에만 위치하면, 그 행/열의 박스 밖 셀에서 그 숫자를 제거할 수 있습니다.',
          'If a digit inside a box appears only in one row (or column), it can be removed from that row/column outside the box.',
        ),
        example:
          '4.27.6...........6568.1..7....85.21.1.......8.87.9.....3..7.8658...........9.84.1',
        status: 'available',
      },
      {
        id: 'claiming',
        techniqueId: 'locked_candidates_claiming',
        title: t('클레이밍 (Claiming)', 'Claiming'),
        desc: t(
          '한 행(또는 열)에서 어떤 숫자가 단 한 박스에만 위치하면, 그 박스 안의 다른 셀에서 그 숫자를 제거할 수 있습니다.',
          'If a digit in a row/column appears only inside one box, it can be removed from the rest of that box.',
        ),
        example:
          '318..54.6...6.381...6.8.5.3864952137123476958795318264.3.5..78......73.5....39641',
        status: 'available',
      },
    ],
  },
  {
    id: 'fish_basic',
    level: 2,
    title: t('4. 첫 Fish (X-Wing 패밀리)', '4. Basic Fish (X-Wing family)'),
    desc: t(
      '한 숫자의 후보 분포가 두 행과 두 열에 걸쳐 직사각형을 이루는 패턴.',
      'A digit forming a rectangle across two rows and two columns.',
    ),
    lessons: [
      {
        id: 'x_wing',
        techniqueId: 'x_wing',
        title: t('엑스윙 (X-Wing)', 'X-Wing'),
        desc: t(
          '두 행에서 어떤 숫자의 후보가 정확히 같은 두 열에만 있으면, 그 두 열의 다른 칸에서 그 숫자를 제거할 수 있습니다. 두 열을 기준으로 한 변형도 동일.',
          'If a digit appears in only the same two columns across two rows, those columns can be cleared elsewhere. The column-based variant is symmetric.',
        ),
        example:
          '000000004760010050090002081070050010000709000080030060240100070010090045900000000',
        status: 'available',
      },
      { id: 'skyscraper', title: t('스카이스크래퍼 (Skyscraper)', 'Skyscraper'), desc: t('X-Wing의 친척. 두 strong link이 한쪽 박스를 공유.', "X-Wing's cousin: two strong links sharing one box."), status: 'coming_soon' },
      { id: 'two_string_kite', title: t('투-스트링 카이트 (2-String Kite)', '2-String Kite'), desc: t('행 strong link과 열 strong link이 한 박스에서 만남.', 'A row link and a column link meeting in one box.'), status: 'coming_soon' },
      { id: 'empty_rectangle', title: t('빈 직사각형 (Empty Rectangle)', 'Empty Rectangle'), desc: t('박스 안 어떤 숫자의 후보들이 한 행과 한 열에 갇혀 있는 패턴.', 'A digit inside a box confined to one row and one column.'), status: 'coming_soon' },
    ],
  },
  {
    id: 'wings',
    level: 3,
    title: t('5. Wing 입문', '5. Wings'),
    desc: t(
      'pivot과 두 pincer로 이뤄지는 짧은 추론. AIC로 가는 다리.',
      'Pivot + pincers — short inferences, the bridge to AIC.',
    ),
    lessons: [
      { id: 'xy_wing', title: t('XY-윙', 'XY-Wing'), desc: t('피봇 XY와 핀서 XZ·YZ → 두 핀서의 공통 가시 칸에서 Z 제거.', 'Pivot XY with pincers XZ and YZ — eliminate Z from cells seeing both pincers.'), status: 'coming_soon' },
      { id: 'xyz_wing', title: t('XYZ-윙', 'XYZ-Wing'), desc: t('피봇이 3후보(XYZ)인 확장형.', 'Three-candidate pivot extension.'), status: 'coming_soon' },
      { id: 'w_wing', title: t('W-윙', 'W-Wing'), desc: t('같은 후보쌍 두 칸이 한 숫자의 strong link로 연결.', 'Two cells of the same pair joined by a strong link.'), status: 'coming_soon' },
    ],
  },
  {
    id: 'uniqueness',
    level: 4,
    title: t('6. 유일성 추론 (Uniqueness)', '6. Uniqueness'),
    desc: t(
      '"퍼즐의 답이 유일하다"는 사실 자체를 추론에 활용.',
      'Use the fact that a valid puzzle has a unique solution.',
    ),
    lessons: [
      { id: 'unique_rectangle_t1', title: t('유니크 렉탱글 Type 1', 'Unique Rectangle (Type 1)'), desc: t('두 박스에 걸친 직사각형 4칸이 같은 후보쌍이면 답이 갈라지므로, 회피 후보를 제거.', 'Four cells in a rectangle sharing the same pair would split the solution — eliminate the offending candidates.'), status: 'coming_soon' },
      { id: 'hidden_rectangle', title: t('히든 렉탱글', 'Hidden Rectangle'), desc: t('UR의 hidden 변형.', 'Hidden variant of UR.'), status: 'coming_soon' },
      { id: 'bug_plus_one', title: t('BUG+1', 'BUG+1'), desc: t('모든 칸이 후보쌍이 되는 상태에 칸 하나만 3후보. 그 3번째 후보가 답.', 'When every cell would be bivalue except one, that cell\'s third candidate is forced.'), status: 'coming_soon' },
    ],
  },
  {
    id: 'fish_extended',
    level: 4,
    title: t('7. Fish 확장 + 컬러링', '7. Extended Fish & Coloring'),
    desc: t(
      'Fish 확장(스워드피쉬·젤리피쉬)과 색칠 그래프 추론.',
      'Fish extensions and coloring-based reasoning.',
    ),
    lessons: [
      { id: 'swordfish', title: t('스워드피쉬', 'Swordfish'), desc: t('3행×3열 fish.', '3-row × 3-column fish.'), status: 'coming_soon' },
      { id: 'jellyfish', title: t('젤리피쉬', 'Jellyfish'), desc: t('4행×4열 fish.', '4-row × 4-column fish.'), status: 'coming_soon' },
      { id: 'finned_x_wing', title: t('핀드 X-윙', 'Finned X-Wing'), desc: t('X-Wing에 핀(여분 후보) 한 개가 더 붙은 형태.', 'X-Wing with an extra "fin" candidate.'), status: 'coming_soon' },
      { id: 'simple_coloring', title: t('심플 컬러링', 'Simple Coloring'), desc: t('한 숫자의 strong link 그래프를 두 색으로 칠해 모순 또는 공통가시 추론.', 'Two-color the strong-link graph of one digit; deduce contradictions and common-sights.'), status: 'coming_soon' },
      { id: 'multi_coloring', title: t('멀티 컬러링', 'Multi-Coloring'), desc: t('여러 색 클러스터 간 상호작용.', 'Interaction across multiple color clusters.'), status: 'coming_soon' },
      { id: 'medusa_3d', title: t('3D 메두사', '3D Medusa'), desc: t('셀+후보 양쪽에 컬러링.', 'Coloring across both cells and candidates.'), status: 'coming_soon' },
    ],
  },
  {
    id: 'chains',
    level: 5,
    title: t('8. 사슬과 AIC (Chains & AIC)', '8. Chains & AIC'),
    desc: t(
      'strong/weak link을 교대로 잇는 사슬 추론. 최강의 일반 도구.',
      'Alternating Inference Chains — the strongest general tool.',
    ),
    lessons: [
      { id: 'remote_pair', title: t('리모트 페어', 'Remote Pair'), desc: t('같은 후보쌍 칸들이 strong link로 길게 이어지는 사슬.', 'A long chain of cells with the same bivalue pair.'), status: 'coming_soon' },
      { id: 'x_chain', title: t('X-체인', 'X-Chain'), desc: t('한 숫자만으로 이뤄진 사슬.', 'A chain using a single digit.'), status: 'coming_soon' },
      { id: 'xy_chain', title: t('XY-체인', 'XY-Chain'), desc: t('bivalue 칸들의 사슬, 양 끝 같은 후보 → 공통가시 제거.', 'Chain of bivalue cells with matching endpoints — clear common sights.'), status: 'coming_soon' },
      { id: 'aic', title: t('AIC (교대 추론 사슬)', 'AIC'), desc: t('가장 일반화된 사슬. strong/weak link을 자유롭게 섞어 사용.', 'The most general chain — strong and weak links freely mixed.'), status: 'coming_soon' },
      { id: 'grouped_aic', title: t('그룹드 AIC', 'Grouped AIC'), desc: t('노드에 cell 그룹 허용.', 'Allows grouped nodes (multiple cells acting as one).'), status: 'coming_soon' },
    ],
  },
  {
    id: 'als',
    level: 6,
    title: t('9. ALS 마스터 (보너스)', '9. ALS Master (bonus)'),
    desc: t(
      'Almost Locked Set — 후보 N+1개의 N칸. 사슬에 강력한 노드.',
      'Almost Locked Sets — N cells with N+1 candidates, powerful chain nodes.',
    ),
    lessons: [
      { id: 'als_xz', title: t('ALS-XZ', 'ALS-XZ'), desc: t('두 ALS가 X로 restricted common, Z 공유 → Z 공통가시 제거.', 'Two ALSs sharing a restricted common X and a Z — eliminate Z from common sights.'), status: 'coming_soon' },
      { id: 'als_xy_wing', title: t('ALS-XY-윙', 'ALS-XY-Wing'), desc: t('세 ALS의 wing 형.', 'Wing-shape of three ALSs.'), status: 'coming_soon' },
      { id: 'death_blossom', title: t('데스 블로섬', 'Death Blossom'), desc: t('stem cell의 각 후보가 ALS petal과 매칭.', "Each of a stem cell's candidates matches an ALS petal."), status: 'coming_soon' },
      { id: 'sue_de_coq', title: t('수 드 코크', 'Sue de Coq'), desc: t('박스-라인 교차의 분리된 두 ALS 그룹.', 'Two separated ALS groups in a box-line intersection.'), status: 'coming_soon' },
    ],
  },
  {
    id: 'computer',
    level: 7,
    title: t('10. 컴퓨터의 영역 (보너스)', '10. The Computer Realm (bonus)'),
    desc: t(
      '실전 풀이엔 잘 안 쓰이는 brute-force 계열. 개념 소개만.',
      'Brute-force-class techniques rarely used by humans — concepts only.',
    ),
    lessons: [
      { id: 'forcing_chain', title: t('포싱 체인', 'Forcing Chain'), desc: t('한 셀의 후보별로 가정해서 공통 결과를 추출.', 'Try each candidate of a cell and extract the common consequence.'), status: 'coming_soon' },
      { id: 'forcing_net', title: t('포싱 넷', 'Forcing Net'), desc: t('가정의 분기 합성.', 'Branching assumption synthesis.'), status: 'coming_soon' },
      { id: 'pattern_overlay', title: t('패턴 오버레이 (POM)', 'Pattern Overlay (POM)'), desc: t('한 숫자의 모든 가능 템플릿의 교집합.', 'Intersect all valid templates of one digit.'), status: 'coming_soon' },
      { id: 'exocet', title: t('엑소셋', 'Exocet'), desc: t('base 2칸 + target 2칸 + companion 칸의 특수 패턴.', 'Special base-target-companion configuration.'), status: 'coming_soon' },
    ],
  },
];
