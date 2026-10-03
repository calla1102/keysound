# 타건음 출처

앱(`KeyboardExtension/Sounds/*.wav`)의 모든 타건음은 아래 원본에서 만들었다. 원본은 이 폴더에 받은 파일명 그대로 두고,
`sh tools/build_sounds.sh` 로 다시 만들 수 있다(결정적 — 같은 원본이면 같은 바이트). 「기본 클릭」은 `python3 tools/make_click.py KeyboardExtension/Sounds/click_press.wav`.

선정 기준(#23): **녹음 파일 자체에 CC0/CC BY 가 명시되고, 업로더가 직접 녹음했다고 밝힌 것**만 쓴다.
라이선스는 2026-10-03 각 페이지의 CC 링크로 확인했다.

| 앱 표기 | 파일 접두어 | 녹음자 | 출처 | 라이선스 | 앱 안 표기 |
| --- | --- | --- | --- | --- | --- |
| 적축 | `red_` | Sadiquecat | Freesound [789628](https://freesound.org/people/Sadiquecat/sounds/789628/) 개별 키 · [789629](https://freesound.org/people/Sadiquecat/sounds/789629/) 엔터 · [789630](https://freesound.org/people/Sadiquecat/sounds/789630/) 스페이스 (Keychron K10, Zoom H2n) | CC0 1.0 | 선택 |
| 갈축 | `brown_` | Foxfire- | Freesound [570754](https://freesound.org/people/Foxfire-/sounds/570754/) 눌림 | CC0 1.0 | 선택 |
| 청축 | `blue_` | UberBosser | Freesound 팩 [23846](https://freesound.org/people/UberBosser/packs/23846/) — 421581 w · 421582 space · 421583 q · 421584 ctrl (폰 녹음) | CC0 1.0 | 선택 |
| 흑축 | `black_` | el_boss | Freesound [643559](https://freesound.org/people/el_boss/sounds/643559/) (Gateron 흑축, 연속 타이핑) | CC0 1.0 | 선택 |
| 무접점 | `topre_` | MakotoHiramatsu | itch.io [Press and Click FREE](https://makotohiramatsu.itch.io/press-click-free) `KEY_PRESS_*.wav` (HHKB, 페이지 문구는 `makotohiramatsu/LICENSE.txt`) | **CC BY 4.0** | **필수** — 저작자·작품명·라이선스 URI·변경 사실(§3(a)(1)) |
| 기본 클릭 | `click_` | (합성) | `tools/make_click.py` 가 생성. 외부 녹음 없음 | — | 불필요 |

## 파일별 구성

- 눌림 `*_press_generic_r0~r4`: 줄마다 다른 소리. 적축·흑축·무접점은 서로 다른 실제 타건 5개, 갈축은 눌림 1개를 ±2.5% 안에서 리샘플한 변주, 청축은 w·q·ctrl·space 눌림 + w 변주 1개.
- 뗌 `*_release_generic`: 적축·청축·흑축·무접점은 녹음 속 실제 뗌 구간. **갈축은 Foxfire- 뗌 녹음(570755)이 바람 잡음이라 쓰지 않고** 눌림을 1.6배 높여 35ms 로 깎은 틱.
- 스페이스·엔터·백스페이스: 적축은 전용 녹음(789629·789630). 나머지는 눌림을 0.90~0.97 배로 낮춘 파생. 청축은 전용 파일 없이 일반 키 소리를 쓴다(`SwitchSound.hasSpecialKeySounds`).
- 흑축 원본은 스펙트럼 차감(14dB, 최대 20dB)으로 잡음을 줄였다. 온셋 검출은 원본에서 한다.
- 무접점은 `KEY_PRESS_*` 22개 중 눌림이 겹치지 않는 9개(001·002·008·009·010·011·018·021·023)만 두었다. `KEY_SEQUENCE_*`·마우스 `CLICK_*` 는 쓰지 않아 제외.
- 공통 가공: 모노 44.1kHz Int16 변환(ffmpeg), 눌림 generic r2 피크 -7dBFS, 뗌 RMS -9dB, 특수키 RMS +3dB 상한, 3ms 페이드인·6~15ms 페이드아웃.

축 표기 근거: 업로더가 제목·설명에 적은 키보드/스위치(#23 코멘트의 조사 기록). Sadiquecat 은 Keychron K10 녹음으로 리니어(적축)로 분류, Foxfire- 는 "Cherry MX Browns", UberBosser 는 "blue switches", el_boss 는 "Gateron Black", MakotoHiramatsu 는 HHKB(정전용량 무접점). Freesound 설명 본문은 2026-10-03 재추출에 실패해 이슈 기록을 따랐다.

## 원본 sha256 (2026-10-03 내려받은 파일)

```
050c675a66af9a86cd7bb9f7da222187f9d1902f6fb27e7297949911ecee7091  sadiquecat/789628__sadiquecat__keychron-k10-a-to-individual-keys.flac
00e67daf88552c137961c95991077b379513a4a6d1f308b4adf1c7f67143b457  sadiquecat/789629__sadiquecat__keychron-k10-enter.wav
7afbdc3daaf8b999a7e1e06ef7cde67a28262ac7ad2068bcc56c9e26242d2739  sadiquecat/789630__sadiquecat__keychron-k10-space_bar.wav
a8bf4851f6ce5f1d3ab2c7ab75ca50637901d531d0af30bf057dc7c00c4e9d1d  foxfire/570754__foxfire__keyboard-press-down.wav
8e848e407ed822b0de1171fcab6c137a4bc7623c661df07f25b4a71fa33c4612  uberbosser/421581__uberbosser__wkey.wav
abbbb7add9467deefd463fca4314bf36d0fcde1cac22cf2765b61bead53e1a6a  uberbosser/421582__uberbosser__spacebarkey.wav
aa5b768ed18118a0e26b796c88752b955ccdee5600be52bd05bc1bc6b0331967  uberbosser/421583__uberbosser__qkey.wav
216b1ed9b84fffca9af2b5a30d4b2e5fba867c22bf1172975fab7a5dd6b1c2ab  uberbosser/421584__uberbosser__ctrlkey.wav
0fa8c6399dc5f041dade1579bf394d0b90ba8bfb4caccf933e00b66463285ec8  el_boss/643559__el_boss__gateron-black-switches-sound.wav
c5c7466c85ef4a7a7292745c3c59d2da0cddedb672e89a699864ba808df0dbae  makotohiramatsu/KEY_PRESS_001.wav
4ae11a8af2ab4cd4c584b26d226e139651bce27c7bc86bd014f02e2e8e2fe81a  makotohiramatsu/KEY_PRESS_002.wav
ae970e6ab821eea9726f0f9f9fc47c0e96a321b284c091d65cddba3a1733dffe  makotohiramatsu/KEY_PRESS_008.wav
2f43bc9fe2abcca0485951635d7f53cf10eadf5b638b143d077686c4bfe08985  makotohiramatsu/KEY_PRESS_009.wav
f9a66b78014c55d1b2432fe534935717fc696b73ea6cc9ee6b99098f6eb03d94  makotohiramatsu/KEY_PRESS_010.wav
b833737bb36471be862bfce0f93a4f97e52f6af8cc1555c70b065077a33e25d7  makotohiramatsu/KEY_PRESS_011.wav
2c4ece5a8fe899a2acdd43bdd7f2a7471a712ae9a86221c2961c11b7355be7a3  makotohiramatsu/KEY_PRESS_018.wav
5968457fa8521a244f855ae4763a5e690caea6e3c5974550e2ea93645fbac4e6  makotohiramatsu/KEY_PRESS_021.wav
6d092b6c3ad207c0ef3664ce6864eb7588c1145ff2477542aa89599e9ec0554e  makotohiramatsu/KEY_PRESS_023.wav
```

## 쓰지 않기로 한 것

- **kbsim**(github.com/tplai/kbsim): 저장소는 MIT 이지만 녹음은 YouTube 타건 영상(Koen Romers·Taeha Types)에서 따온 것으로 저자가 밝힘(tplai/kbsim#22). 2026-10-03 전부 제거.
- Mechvibes 내장 팩(녹음자 불명), daktilo(출처 없음), bucklespring(GPL)·geneotech(AGPL), Pixabay(재배포 제한), CC BY-NC·AI 생성 녹음.
- 후보였으나 탈락: ujonathan 628325(잡음·밀집), StavSounds 팩 42151(직접 녹음 진술 없음), Foxfire- 570755 뗌(바람 잡음).
