# 스도콩 (sudokong)

기본에 충실한 스도쿠 앱. Flutter 앱(`app/`)과 순수 Dart 엔진(`packages/sudoku_engine/`)으로 나뉜 Dart pub workspace 모노레포입니다.

## 구조

```
pubspec.yaml                 # workspace 루트 (멤버: packages/sudoku_engine, app)
packages/sudoku_engine/      # UI 의존 없는 엔진: 테이블, 코덱, 솔버, 생성기 (Isolate.run 안전)
app/
  lib/main.dart, app.dart    # 앱 진입, 테마/라이프사이클
  lib/core/theme/            # 색 토큰(board_colors), 테마(app_theme), 색상 테마 심(color_theme)
  lib/features/play/         # 게임 상태(model/), 컨트롤러, 타이머, 화면과 위젯(widgets/)
  lib/features/settings/     # 설정 모델/저장/화면
  lib/features/help/         # 용어 설명
  test/                      # 단위·위젯 테스트, 색 대비 가드, 스크린샷 렌더
design/                      # 초기 목업과 앱 아이콘 원본
```

게임 로직은 불변 `PlayState`와 순수 함수 `reduce(state, intent)`로만 바뀝니다. 보드는 `BoardPainter` 하나로 그리고, 모든 색은 `BoardColors` 토큰에서만 가져옵니다.

## 명령

```
cd app
dart format lib test
flutter analyze
flutter test                                   # 단위·위젯 테스트
SUDOKONG_SCREENSHOT=1 flutter test test/screenshot   # 화면 PNG → app/build/screenshots/
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk

cd packages/sudoku_engine && dart test
```

## 디자인 규칙

- 색은 `app/lib/core/theme/board_colors.dart`에서만 바꿉니다. `app/test/board_colors_contrast_test.dart`가 WCAG 대비(후보수 4.5:1 등)를 지키는지 막아 줍니다.
- 라이트는 순백 없이, 다크는 중립 다크 그레이. 기본수·입력수·후보수는 서로 다른 색입니다.
- 글꼴은 Pretendard 하나로 통일합니다.
