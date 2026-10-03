# 타건음 출처

앱(`KeyboardExtension/Sounds/*.wav`)의 모든 타건음은 아래 원본에서 만들었다. 원본은 이 폴더에 받은 파일명 그대로 두고,
`sh tools/build_sounds.sh` 로 다시 만들 수 있다(결정적 — 같은 원본이면 같은 바이트. ffmpeg 8.1.2 기준, 48kHz·24bit·mp3 원본은 ffmpeg 리샘플러·디코더가 바뀌면 달라질 수 있다). 「기본 클릭」은 `python3 tools/make_click.py KeyboardExtension/Sounds/click_press.wav`.

선정 기준(#23): **녹음 파일 자체에 CC0/CC BY 가 명시되고, 업로더가 직접 녹음했다고 밝힌 것**만 쓴다.
라이선스는 2026-10-03 각 페이지의 CC 링크로 확인했다.

| 앱 표기 | 파일 접두어 | 녹음자 | 출처 | 라이선스 | 앱 안 표기 |
| --- | --- | --- | --- | --- | --- |
| 적축 | `red_` | Sadiquecat | Freesound [789628](https://freesound.org/people/Sadiquecat/sounds/789628/) 개별 키 · [789629](https://freesound.org/people/Sadiquecat/sounds/789629/) 엔터 · [789630](https://freesound.org/people/Sadiquecat/sounds/789630/) 스페이스 (Keychron K10, Zoom H2n) | CC0 1.0 | 선택 |
| 갈축 | `brown_` | Foxfire- | Freesound [570754](https://freesound.org/people/Foxfire-/sounds/570754/) 눌림 | CC0 1.0 | 선택 |
| 청축 | `blue_` | UberBosser | Freesound 팩 [23846](https://freesound.org/people/UberBosser/packs/23846/) — 421581 w · 421582 space · 421583 q · 421584 ctrl (폰 녹음) | CC0 1.0 | 선택 |
| 흑축 | `black_` | el_boss | Freesound [643559](https://freesound.org/people/el_boss/sounds/643559/) (Gateron 흑축, 연속 타이핑) | CC0 1.0 | 선택 |
| 무접점 | `topre_` | MakotoHiramatsu | itch.io [Press and Click FREE](https://makotohiramatsu.itch.io/press-click-free) `KEY_PRESS_*.wav` (HHKB, 페이지 문구는 `makotohiramatsu/LICENSE.txt`) | **CC BY 4.0** | **필수** — 저작자·작품명·라이선스 URI·변경 사실(§3(a)(1)) |
| 멤브레인 | `membrane_` | Geoff-Bremner-Audio | Freesound [705787](https://freesound.org/s/705787/) 「HP Office Keyboard」(사무용 HP 키보드, Sennheiser MKH50, 연속 타이핑) | **CC BY 4.0** | **필수** — 저작자·작품명·라이선스 URI·변경 사실 |
| 버클링 스프링 | `buckling_` | SamsterBirdies | Freesound [489423](https://freesound.org/s/489423/) (Unicomp 버클링 스프링, BOYA BY-M1, 연속 타이핑 2분 16초) | CC0 1.0 | 선택 |
| 노트북 | `laptop_` | justamudkip | Freesound [853602](https://freesound.org/s/853602/) (2021 MacBook Pro 14인치, DJI Mic, 연속 타이핑) | CC0 1.0 | 선택 |
| 도각 리니어 | `thock_` | Techrul | Freesound [815614](https://freesound.org/s/815614/) (Wobkey Rainy 75, 축 종류 미표기, 원본 mp3, 연속 타이핑) | CC0 1.0 | 선택 |
| 구형 데스크탑 | `desktop_` | suckmadeck | Freesound [676417](https://freesound.org/people/suckmadeck/sounds/676417/) 「Typing on a 2002 Apple Mac keyboard」(2002년 데스크탑 키보드, 연속 타이핑 2분 10초) | CC0 1.0 | 선택 |
| 얇은 무선 키보드 | `scissor_` | SoundsLikeFoley | Freesound [421031](https://freesound.org/people/SoundsLikeFoley/sounds/421031/) 「Typing on Logitech K811 keyboard」(소형 블루투스 키보드, 연속 타이핑 1분 31초) | **CC BY 4.0** | **필수** — 저작자·작품명·라이선스 URI·변경 사실 |
| 전동 타자기 | `typewriter_` | secretmojo | Freesound [224012](https://freesound.org/people/secretmojo/sounds/224012/) 「Typewriter IBM Selectric II」(전동 타자기, 연속 타이핑 2분 3초, 원본 flac) | CC0 1.0 | 선택 |
| 기본 클릭 | `click_` | (합성) | `tools/make_click.py` 가 생성. 외부 녹음 없음 | — | 불필요 |

## 파일별 구성

- 눌림 `*_press_generic_r0~r4`: 줄마다 다른 소리. 적축·흑축·무접점은 서로 다른 실제 타건 5개, 갈축은 눌림 1개를 ±2.5% 안에서 리샘플한 변주, 청축은 w·q·ctrl·space 눌림 + w 변주 1개.
- 뗌 `*_release_generic`: 적축·청축·흑축·무접점은 녹음 속 실제 뗌 구간. **갈축은 Foxfire- 뗌 녹음(570755)이 바람 잡음이라 쓰지 않고** 눌림을 1.6배 높여 35ms 로 깎은 틱.
- 스페이스·엔터·백스페이스: 적축은 전용 녹음(789629·789630). 나머지는 눌림을 0.90~0.97 배로 낮춘 파생. 청축은 전용 파일 없이 일반 키 소리를 쓴다(`SwitchSound.hasSpecialKeySounds`).
- 흑축 원본은 스펙트럼 차감(14dB, 최대 20dB)으로 잡음을 줄였다. 온셋 검출은 원본에서 한다.
- 무접점은 `KEY_PRESS_*` 22개 중 눌림이 겹치지 않는 9개(001·002·008·009·010·011·018·021·023)만 두었다. `KEY_SEQUENCE_*`·마우스 `CLICK_*` 는 쓰지 않아 제외.
- #42 추가 4종(멤브레인·버클링 스프링·노트북·도각 리니어)은 모두 연속 타이핑 녹음이라 `from_continuous` 로 같은 방식으로 자른다: 온셋 검출 → 녹음 안 95번째 백분위 피크 기준 12dB 안의 눌림 중 150ms 안에 다른 눌림이 없는 것 8개 → 시작이 깨끗한 5개를 r0~r4. 뗌은 눌림 뒤 40~150ms 의 절반 이하 소리. 스페이스·엔터·백스페이스는 눌림을 0.90~0.97 배로 낮춘 파생.
  - 버클링 스프링은 뗌 소리가 눌림만큼 커서(스프링 복귀) 「눌림 → 50~160ms 뒤 온셋 하나 → 300ms 공백」인 단어 끝 타건만 (눌림, 뗌) 쌍으로 쓰고, 바닥 잡음은 스펙트럼 차감 10dB. 눌림 길이 90ms(울림), 노트북 60ms, 멤브레인 70ms, 도각 리니어 80ms.
- #47 추가 3종(구형 데스크탑·얇은 무선 키보드·전동 타자기)도 `from_continuous` 로 자른다(눌림 길이 70·60·90ms). 원본이 스테레오·48kHz(96kHz)라 ffmpeg 가 모노 44.1kHz 로 내린다.
  - 전동 타자기는 키 소리 외 캐리지·벨·모터 울림이 섞이므로 `max_tail_db=-15` 로 눌림 뒤 150~400ms 가 첫 30ms 보다 15dB 이상 가라앉는 고립된 타건만 쓴다. 뗌 소리가 없는 기계라 뗌은 눌림을 1.6배 높여 깎은 틱이다.
  - 얇은 무선 키보드는 짧고 얇아 폰 스피커에서 작게 들려 눌림 r2 피크 -3dBFS(+4dB, 노트북과 같음).
  - 앱 표시 이름은 상표명(IBM·Selectric·Apple·Logitech) 대신 일반명. 위 표의 원본 작품명 인용은 CC BY 저작자 표기용이다.
- 공통 가공: 모노 44.1kHz Int16 변환(ffmpeg), 눌림 generic r2 피크 -7dBFS, 뗌 RMS -9dB, 특수키 RMS +3dB 상한, 3ms 페이드인·6~15ms 페이드아웃.

축 표기 근거: 업로더가 제목·설명에 적은 키보드/스위치(#23 코멘트의 조사 기록). Sadiquecat 은 Keychron K10 녹음으로 리니어(적축)로 분류, Foxfire- 는 "Cherry MX Browns", UberBosser 는 "blue switches", el_boss 는 "Gateron Black", MakotoHiramatsu 는 HHKB(정전용량 무접점). Freesound 설명 본문은 2026-10-03 재추출에 실패해 이슈 기록을 따랐다. #42 추가분의 설명 본문은 2026-10-03 스크립트로 추출해 확인했다: Geoff-Bremner-Audio "Typing on an office HP keyboard, recorded with a Sennheiser MKH50. Sound by Geoff Bremner", SamsterBirdies "Recording typing on a Unicomp buckling spring keyboard with a BOYA BY-M1", justamudkip "The sounds of me typing on a 2021 14\" MacBook Pro keyboard", Techrul "I just typed on my Rainy 75 keyboard"(축 종류 미표기 → 앱 표기는 소리 특성인 「도각 리니어」, 윤활·흡음 여부는 원본에 근거가 없어 설명에 쓰지 않음).

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
d8a97b68f300cb3de5ad685ef53ffafbac980422c49ef50c3a1b12fcac7d5658  geoff-bremner-audio/705787__geoff-bremner-audio__hp-office-keyboard.wav
b4618ae0dde6160de31d856b878216a3efeb7f60cb0a16e8835b00b9a95feb56  samsterbirdies/489423__samsterbirdies__typing-on-a-keyboard.flac
bf7be3720307c6b31dcd902f99c41f3409b88a2d903ac97d9e8be775e87028fb  justamudkip/853602__justamudkip__typing-on-laptop-keyboard-2.wav
a4b9438d749cd3da510bd5a967974e5988321a6aeda426094ffd2edf0f47d9ec  techrul/815614__techrul__typing-on-a-rainy-75.mp3
05beac061d5a3037900f77e12bf83ebc547227954aaafaa912e6a5322da4bf27  suckmadeck/676417__suckmadeck__typing-on-a-2002-apple-mac-keyboard.wav
7b6e9e7685c0363d888ed90afbe97461cea55b0dbddb15b89fa911a7c1637436  soundslikefoley/421031__soundslikefoley__typing-on-logitech-k811-keyboard.wav
941f40f15d77983541a520e0be6aeb85d98a043bfc24060b978943343973697b  secretmojo/224012__secretmojo__typewriter-ibm-selectric-ii.flac
```

## 쓰지 않기로 한 것

- **kbsim**(github.com/tplai/kbsim): 저장소는 MIT 이지만 녹음은 YouTube 타건 영상(Koen Romers·Taeha Types)에서 따온 것으로 저자가 밝힘(tplai/kbsim#22). 2026-10-03 전부 제거.
- Mechvibes 내장 팩(녹음자 불명), daktilo(출처 없음), bucklespring(GPL)·geneotech(AGPL), Pixabay(재배포 제한), CC BY-NC·AI 생성 녹음.
- 후보였으나 탈락: ujonathan 628325(잡음·밀집), StavSounds 팩 42151(직접 녹음 진술 없음), Foxfire- 570755 뗌(바람 잡음).
- #42 조사(이슈 #42 코멘트): zrrion 685984 알프스(저비트레이트 mp3, 타건 검출 0), bangcorrupt 833612(CC0 이나 설명에 비상업 문구), 저소음·광축·리얼포스 계열은 CC0/CC BY 녹음 없음.
