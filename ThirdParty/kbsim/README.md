# kbsim 사운드

- 출처: https://github.com/tplai/kbsim (MIT, Copyright (c) Thomas Lai)
- 기준 커밋: ba103f3b0afa9dab80447aa2e7e2ed80b6bd80e4 (2021-12-23)
- 사용 중인 축: `mxbrown` → 앱 표기 「갈축」 (상표명 대신 일반명)
- 변환: `src/assets/audio/mxbrown/{press,release}/*.mp3` 를
  `afconvert -f WAVE -d LEI16@44100 -c 1` 로 wav 변환 → `KeyboardExtension/Sounds/brown_<press|release>_<이름>.wav`
  (AudioServices 시스템 사운드는 mp3 를 공식 지원하지 않아 wav 로 둔다)
- 오디오 자체 라이선스는 저장소에 따로 명시돼 있지 않다. 앱 내 출처 표기 화면에 저장소·저자·MIT 고지를 넣을 것.
