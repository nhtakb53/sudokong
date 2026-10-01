import 'package:flutter/material.dart';

import '../settings/widgets/settings_section.dart';

/// Short explanations of the words the app and basic sudoku use.
class GlossaryScreen extends StatelessWidget {
  const GlossaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(title: Text('용어 설명')),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList.list(
              children: [
                for (var i = 0; i < _sections.length; i++) ...[
                  if (i > 0) const SizedBox(height: 24),
                  SettingsSection(
                    title: _sections[i].title,
                    children: [
                      for (final term in _sections[i].terms) _TermTile(term),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section {
  const _Section(this.title, this.terms);
  final String title;
  final List<_Term> terms;
}

class _Term {
  const _Term(this.name, this.body);
  final String name;
  final String body;
}

class _TermTile extends StatelessWidget {
  const _TermTile(this.term);

  final _Term term;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      // Stretch, or a one-line entry gets centered by the section column.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            term.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            term.body,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

const _sections = [
  _Section('보드', [
    _Term(
      '행 · 열 · 박스',
      '가로 아홉 칸이 행, 세로 아홉 칸이 열, 굵은 선으로 나뉜 3×3 묶음이 박스예요. '
          '행, 열, 박스마다 1부터 9까지 한 번씩만 들어가요.',
    ),
    _Term('유닛', '행, 열, 박스를 통틀어 부르는 말이에요. 유닛은 모두 27개예요.'),
    _Term('주어진 숫자', '퍼즐이 시작될 때 이미 적혀 있는 숫자예요. 진한 색으로 보이고 바꿀 수 없어요.'),
    _Term('입력 숫자', '내가 적어 넣은 숫자예요. 파란색으로 보여요.'),
    _Term(
      '충돌',
      '같은 행, 열, 박스 안에 같은 숫자가 두 번 들어간 상태예요. '
          '그 숫자가 빨간색으로 바뀌어요.',
    ),
  ]),
  _Section('후보와 메모', [
    _Term(
      '후보 (후보수)',
      '어떤 칸에 아직 들어갈 수 있는 숫자들이에요. '
          '같은 행, 열, 박스에 이미 있는 숫자는 후보에서 빠져요.',
    ),
    _Term(
      '메모',
      '칸 안에 작게 적어 두는 후보예요. 메모 버튼을 켜면 숫자 키가 메모를 적고, '
          '키를 꾹 누르면 메모 모드여도 숫자가 바로 들어가요.',
    ),
    _Term('후보 채움', '모든 빈 칸에 규칙상 가능한 후보를 메모로 한 번에 적어요.'),
    _Term(
      '후보 2개 · 후보 3개',
      '메모가 정확히 2개(또는 3개) 남은 칸을 색으로 채워요. '
          '켜 두는 동안 메모가 바뀌면 바로 따라와요.',
    ),
  ]),
  _Section('강조', [
    _Term(
      '같은 숫자 강조',
      '숫자 키를 누르거나 숫자가 있는 칸을 누르면 보드의 같은 숫자와 '
          '그 숫자의 메모가 강조돼요.',
    ),
    _Term(
      '여러 숫자 강조',
      '칸을 고르지 않은 채 숫자 키를 꾹 누르면 그 숫자가 강조 목록에 더해지고, '
          '숫자마다 다른 색이 붙어요. 아홉 개를 모두 켤 수도 있어요. '
          '다시 꾹 누르면 빠지고, 빈 곳을 누르면 모두 꺼져요.',
    ),
    _Term(
      '지우개',
      '툴바의 지우개 버튼이에요. 칸 먼저 모드에서 내가 채운 칸을 고른 채 누르면 '
          '그 칸이 바로 지워지고(숫자 먼저, 그다음 메모·색칠), 그 밖에는 지우개가 '
          '장전되어 누르는 칸마다 지워져요. 툴바의 지우기 메뉴에서 연결만, '
          '칸 색칠만, 후보 색칠만, 또는 모두를 한 번에 지울 수 있어요. '
          '툴바 버튼은 꾹 누르면 이름이 떠요.',
    ),
    _Term(
      '색칠',
      '숫자 키 아래 색 줄에서 색을 누르면 그 색이 장전되고, 칸을 누르면 칠해져요. '
          '칸을 꾹 누르면 누른 자리에 가장 가까운 후보수가 칠해지고, '
          '"후보 색칠" 버튼을 켜 두면 그냥 눌러도 후보수가 칠해져요. '
          '같은 색으로 다시 누르거나 지우개를 장전한 채 누르면 지워지고, '
          '지우개를 꾹 누르면 색칠이 모두 지워져요. 숫자 키를 누르면 바로 숫자 입력으로 '
          '돌아오고, 실행취소로도 되돌릴 수 있어요.',
    ),
    _Term(
      '연결 (강한 결합 · 약한 결합)',
      '"연결"을 켜고 후보수 둘을 차례로 누르면 그 사이에 선이 그어져요. 두 후보가 '
          '한 칸에 둘뿐이거나, 같은 숫자가 한 줄·열·박스에 두 칸뿐이면 강한 결합(실선), '
          '아니면 약한 결합(점선)이에요. 마지막 후보가 새 시작점이라 계속 누르면 '
          '체인이 이어지고, 같은 후보를 다시 누르면 끝나요. 선 가운데 점을 누르면 '
          '강·약을 바꾸고, 지우개로 점을 누르면 지워져요. 설정의 "연결 표시"로 '
          '항상 보일지, 그 숫자를 강조했을 때만 보일지 고를 수 있어요.',
    ),
    _Term(
      '켤레쌍 자동 표시',
      '툴바의 켤레쌍 버튼을 켜면 강조한 숫자의 켤레쌍, 즉 한 줄·열·박스에 '
          '그 숫자 후보가 딱 두 칸뿐인 쌍이 얇은 선으로 자동 표시돼요. '
          '앱을 껐다 켜도 켜진 채로 남고, X-체인과 컬러링의 출발점을 찾기 좋아요.',
    ),
    _Term(
      '가정 모드',
      '툴바의 가정 버튼을 누르면 그 순간이 기억되고, 이후 둔 숫자는 보라색으로 보여요. '
          '보드 테두리도 보라색이 돼요. 버튼을 다시 누르면 "확정하기"로 그대로 두거나 '
          '"시작 시점으로 되돌리기"로 한 번에 물릴 수 있어요. 다 풀면 자동으로 확정돼요.',
    ),
    _Term(
      '칸 먼저 · 숫자 먼저',
      '설정의 입력 방식이에요. 칸 먼저는 칸을 고른 뒤 숫자를 누르고, '
          '숫자 먼저는 숫자를 고른 뒤 칸을 눌러요. '
          '숫자 먼저에서는 칸을 꾹 누르면 메모 모드여도 숫자가 들어가요.',
    ),
  ]),
  _Section('기본 기법', [
    _Term('네이키드 싱글', '후보가 하나뿐인 칸이에요. 그 숫자가 답이에요.'),
    _Term(
      '히든 싱글',
      '한 유닛 안에서 어떤 숫자가 들어갈 수 있는 칸이 하나뿐일 때예요. '
          '그 칸의 다른 후보는 모두 지워도 돼요.',
    ),
    _Term(
      '네이키드 페어',
      '한 유닛의 두 칸이 똑같은 두 후보만 가질 때예요. '
          '그 유닛의 다른 칸에서 그 두 숫자를 지울 수 있어요. '
          '후보 2개 버튼으로 찾기 쉬워요.',
    ),
    _Term(
      '네이키드 트리플',
      '한 유닛의 세 칸이 세 후보만 나눠 가질 때예요. '
          '나머지 칸에서 그 세 숫자를 지울 수 있어요. 후보 3개 버튼이 도움이 돼요.',
    ),
  ]),
];
