# 타건음 출처

앱(`KeyboardExtension/Sounds/*.wav`)의 모든 타건음은 아래 원본에서 만들었다. 원본은 이 폴더에 받은 파일명 그대로 두고,
`tools/build_sounds.sh` 로 다시 만들 수 있다(결정적 — 같은 원본이면 같은 바이트).

선정 기준(#23): **녹음 파일 자체에 CC0/CC BY 가 명시되고, 업로더가 직접 녹음했다고 밝힌 것**만 쓴다.
라이선스는 2026-10-03 각 페이지의 CC 링크로 확인했다.

| 앱 표기 | 파일 접두어 | 녹음자 | 출처 | 라이선스 | 앱 안 표기 |
| --- | --- | --- | --- | --- | --- |
| 적축 | `red_` | Sadiquecat | Freesound [789628](https://freesound.org/people/Sadiquecat/sounds/789628/) 개별 키 · [789629](https://freesound.org/people/Sadiquecat/sounds/789629/) 엔터 · [789630](https://freesound.org/people/Sadiquecat/sounds/789630/) 스페이스 (Keychron K10, Zoom H2n) | CC0 1.0 | 선택 |
| 갈축 | `brown_` | Foxfire- | Freesound [570754](https://freesound.org/people/Foxfire-/sounds/570754/) 눌림 | CC0 1.0 | 선택 |
| 청축 | `blue_` | UberBosser | Freesound 팩 [23846](https://freesound.org/people/UberBosser/packs/23846/) — 421581 w · 421582 space · 421583 q · 421584 ctrl (폰 녹음) | CC0 1.0 | 선택 |
| 흑축 | `black_` | el_boss | Freesound [643559](https://freesound.org/people/el_boss/sounds/643559/) (Gateron 흑축, 연속 타이핑) | CC0 1.0 | 선택 |
| 무접점 | `topre_` | MakotoHiramatsu | itch.io [Press and Click FREE](https://makotohiramatsu.itch.io/press-click-free) `KEY_PRESS_*.wav` (HHKB) | **CC BY 4.0** | **필수** — 녹음자·작품명·라이선스 |
| 기본 클릭 | `click_` | (합성) | `tools/make_click.py` 가 생성. 외부 녹음 없음 | — | 불필요 |

## 파일별 구성

- 눌림 `*_press_generic_r0~r4`: 줄마다 다른 소리. 적축·흑축·무접점은 서로 다른 실제 타건 5개, 갈축은 눌림 1개를 ±2.5% 안에서 리샘플한 변주, 청축은 w·q·ctrl·space 눌림 + w 변주 1개.
- 뗌 `*_release_generic`: 적축·청축·흑축·무접점은 녹음 속 실제 뗌 구간. **갈축은 Foxfire- 뗌 녹음(570755)이 바람 잡음이라 쓰지 않고** 눌림을 1.6배 높여 35ms 로 깎은 틱.
- 스페이스·엔터·백스페이스: 적축은 전용 녹음(789629·789630). 나머지는 눌림을 0.90~0.97 배로 낮춘 파생. 청축은 전용 파일 없이 일반 키 소리를 쓴다(`SwitchSound.hasSpecialKeySounds`).
- 흑축 원본은 스펙트럼 차감(14dB, 최대 20dB)으로 잡음을 줄였다. 온셋 검출은 원본에서 한다.
- 무접점은 `KEY_PRESS_*` 22개 중 눌림이 겹치지 않는 9개(001·002·008·009·010·011·018·021·023)만 두었다. `KEY_SEQUENCE_*`·마우스 `CLICK_*` 는 쓰지 않아 제외.
- 공통 가공: 모노 44.1kHz Int16 변환(ffmpeg), 눌림 generic r2 피크 -7dBFS, 뗌 RMS -9dB, 특수키 RMS +3dB 상한, 3ms 페이드인·6~15ms 페이드아웃.

## 쓰지 않기로 한 것

- **kbsim**(github.com/tplai/kbsim): 저장소는 MIT 이지만 녹음은 YouTube 타건 영상(Koen Romers·Taeha Types)에서 따온 것으로 저자가 밝힘(tplai/kbsim#22). 2026-10-03 전부 제거.
- Mechvibes 내장 팩(녹음자 불명), daktilo(출처 없음), bucklespring(GPL)·geneotech(AGPL), Pixabay(재배포 제한), CC BY-NC·AI 생성 녹음.
- 후보였으나 탈락: ujonathan 628325(잡음·밀집), StavSounds 팩 42151(직접 녹음 진술 없음), Foxfire- 570755 뗌(바람 잡음).
