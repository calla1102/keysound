# kbsim 사운드

- 출처: https://github.com/tplai/kbsim (MIT, Copyright (c) Thomas Lai)
- 기준 커밋: ba103f3b0afa9dab80447aa2e7e2ed80b6bd80e4 (2021-12-23)
- 사용 중인 축: `mxbrown` → 앱 표기 「갈축」 (상표명 대신 일반명)
- 변환: `src/assets/audio/mxbrown/{press,release}/*.mp3` 를
  `afconvert -f WAVE -d LEI16@44100 -c 1` 로 wav 변환 → `KeyboardExtension/Sounds/brown_<press|release>_<이름>.wav`
  (AudioServices 시스템 사운드는 mp3 를 공식 지원하지 않아 wav 로 둔다)
- 오디오 자체 라이선스는 저장소에 따로 명시돼 있지 않다. 앱 내 출처 표기 화면에 저장소·저자·MIT 고지를 넣을 것.

## 추가 축 (#13)

같은 저장소·같은 기준 커밋(ba103f3)에서 가져왔고 변환 방법도 위와 같다.
파일 이름은 `<접두어>_<press|release>_<이름 소문자>.wav` (예 `mxblue/press/GENERIC_R0.mp3` → `blue_press_generic_r0.wav`).

| kbsim 폴더 | 앱 표기 | 접두어 | 비고 |
| --- | --- | --- | --- |
| `mxblue` | 청축 | `blue` | space·enter·backspace 녹음 없음 → 앱이 일반 키 소리(r2)로 대체 |
| `redink` | 적축 | `red` | |
| `mxblack` | 흑축 | `black` | |
| `topre` | 무접점 | `topre` | |

- 메인 앱 미리듣기용으로 `*_press_generic_r2.wav` 와 `click_press.wav` 만 앱 번들에도 들어간다(`project.yml` 의 Keysound 타깃 sources).
- 오디오 파일 자체의 라이선스: kbsim 저장소·README 어디에도 녹음 출처·별도 라이선스 표기가 없다. 저장소 전체가 MIT(LICENSE.md)라는 사실만 확인했고, 녹음 원저작자는 **확인하지 못했다.** 출시 전 저자(tplai)에게 확인하거나 자체 녹음으로 교체를 고려할 것.
