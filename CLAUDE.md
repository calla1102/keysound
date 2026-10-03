# Project: Keysound — 기계식 키보드 소리 커스텀 키보드 (iOS)

축(청축·갈축·적축 등)별 타건음을 앱에서 골라 두면, 다른 앱에서 타이핑할 때도 그 소리가 나는 iOS 커스텀 키보드.
1인 개인 프로젝트다. 노션 팀 보드·스프린트 번호·QA 회차 규칙(languageforest 전용)은 여기에 적용하지 않는다.

## 확정된 기술 결정 (재조사하지 않는다)

- **커스텀 키보드 익스텐션(UIInputViewController)** 방식. OS 기본 키보드에 소리만 덧씌우는 건 불가.
- **Full Access 불필요** (2026-10-02 iPhone 17 Pro·iOS 27 실측). OFF 에서도
  AudioServices 커스텀 wav 재생 · App Group 읽기 · 익스텐션 자체 UserDefaults 가 모두 된다.
  **AVAudioPlayer 는 OFF 에서 `play()` false** → 재생은 AudioServices(`AudioServicesCreateSystemSoundID`) 로만 한다.
- 축 선택은 메인 앱에서 하고 App Group(`group.com.minnnj.keysound`)으로 익스텐션에 넘긴다.
- 한글 두벌식 오토마타는 직접 구현(`Packages/HangulEngine`).
- **익스텐션에 네트워크 코드를 넣지 않는다.** 심사 설명·신뢰의 근거다.

## 라이선스 ⚠️

- **글쇠(github.com/iphonebreak/geulsoe-keyboard)는 라이선스가 없다 → 코드 복사 금지, 구조 참고만.**
- **kbsim 녹음은 쓰지 않는다** — YouTube 타건 영상 발췌로 확인(#23). 코드가 MIT 여도 녹음 권리는 별개다.
- 타건음은 **녹음 파일 자체에 CC0/CC BY 가 명시되고 업로더가 직접 녹음했다고 밝힌 것**만 쓴다(NC·ND·AI 생성·출처 불명 제외).
  원본·출처표는 `ThirdParty/`(`CREDITS.md`), 재생성은 `ThirdParty/tools/build_sounds.sh`. CC BY 는 앱 안 출처 표기가 의무다.
- 상표명(Cherry MX·Topre 등) 대신 청축·적축·무접점 같은 일반명을 쓴다.

## 구조

- `project.yml` — XcodeGen 정의. **`Keysound.xcodeproj` 는 gitignore 라 항상 `xcodegen generate` 로 만든다.** 타깃·설정은 xcodeproj 가 아니라 project.yml 을 고친다.
- `App/` — SwiftUI 메인 앱 (`com.minnnj.keysound`)
- `KeyboardExtension/` — UIKit 키보드 익스텐션 (`com.minnnj.keysound.keyboard`), `Sounds/*.wav`
- `Shared/` — 두 타깃이 함께 컴파일하는 코드(App Group 상수 등)
- `Packages/HangulEngine/` — 두벌식 오토마타 SwiftPM 패키지 + 테스트
- `ThirdParty/` — 외부 사운드 원본과 라이선스

## 빌드 & 실행

```bash
xcodegen generate
# 시뮬레이터 빌드(서명 없이) — 커밋 전 기본 검증
xcodebuild -project Keysound.xcodeproj -scheme Keysound \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
# 패키지 테스트
(cd Packages/HangulEngine && swift test)
# 앱 유닛 테스트(KeysoundTests, 시뮬레이터 필요)
xcodebuild -project Keysound.xcodeproj -scheme Keysound \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO test
# 실기기(iPhone 17 Pro) 빌드·설치·실행
xcodebuild -project Keysound.xcodeproj -scheme Keysound \
  -destination 'id=00008150-000628481407801C' -allowProvisioningUpdates build
xcrun devicectl device install app --device 847FCEEC-D35D-580C-AA82-401FA740F841 <DerivedData>/Build/Products/Debug-iphoneos/Keysound.app
xcrun devicectl device process launch --device 847FCEEC-D35D-580C-AA82-401FA740F841 com.minnnj.keysound
```

- xcodebuild 와 devicectl 의 기기 식별자가 **다르다**(위 두 값).
- 자동 서명이 Apple 약관(PLA) 미동의로 실패하면 developer.apple.com > 계정 배너에서 동의한다.
- 키보드 익스텐션은 실기기에서만 진짜 동작을 확인할 수 있다(소리·전환·메모리 한도). 시뮬레이터 빌드 통과는 컴파일 검증일 뿐이다.

## 커밋 & PR

- 브랜치: `main` 은 보호 브랜치(전역 훅이 직접 커밋·푸시 차단). 작업은 `feat/`·`fix/`·`chore/`·`refactor/`·`docs/` 브랜치에서 하고 PR 로 squash 머지한다.
- 커밋·PR 제목: conventional 한국어 — `feat: 두벌식 오토마타 추가`. 대괄호 타입·`[#번호]` 접두어 없음.
- `Co-Authored-By` 트레일러·`Generated with Claude Code` 푸터 금지(전역 규칙).
- **커밋 전 검증은 `.claude/hooks/enforce-build.sh` 가 강제한다.** Swift·project.yml·리소스 변경이 있으면 바뀐 패키지 `swift test` + `xcodegen generate` + 시뮬레이터 빌드(App·Shared·Tests·project.yml 변경 시 앱 유닛 테스트 `test` 로 대체)를 돌리고 실패 시 차단. 긴급 우회는 `SKIP_BUILD=1`.
- **PR 생성은 `/pr` 로만.** `gh pr create` 직접 호출은 `enforce-pr-skill.sh` 가 차단한다.
- 머지는 `gh pr merge <N> --squash`. `--delete-branch` 금지(`guard-pr-merge.sh` 가 차단).
- GitHub: `calla1102/keysound` (private).
- **작업 1개 = GitHub 이슈 1 + 브랜치 1 + PR 1.** (languageforest 의 노션 행·이슈·브랜치·PR 세트에서 노션을 뺀 것)
  - 브랜치 이름 `<type>/<이슈번호>-<이름>` (예 `fix/2-fast-typing`). 매핑 파일 없이 브랜치 이름이 이슈를 가리킨다.
  - `/new-feature #N` 또는 `/new-feature <설명>`(이슈부터 생성) → 작업 → `/pr` 이 본문 끝에 `Closes #N` 을 넣고, 머지 때 이슈가 자동으로 닫힌다.
  - `Closes #N` 없는 PR 생성은 `enforce-pr-skill.sh` 가 차단한다.
  - 라벨: `feat`→`enhancement`, `fix`→`bug`, `docs`→`documentation`, `chore`·`refactor`→ 없음 (이슈·PR 공통).

## Subagent 활용 (`.claude/agents/`)

| 작업 종류                                | Subagent                | 트리거 발화 예시                                   |
| ---------------------------------------- | ----------------------- | -------------------------------------------------- |
| Swift/SwiftUI/UIKit 구현·XcodeGen·서명   | `ios-dev`               | "이 화면 만들어줘", "project.yml", "빌드 에러"     |
| 시니어 코드 리뷰 (read-only)             | `ios-tech-lead`         | "시니어 리뷰", "이거 괜찮아?"                      |
| 키보드 정적 QA + 실기기 체크리스트       | `keyboard-qa-reviewer`  | "검수", "실기기 체크리스트", 키보드 UI·사운드 변경 |
| PR 리뷰 코멘트 반영                      | `pr-feedback-applier`   | "리뷰 반영해줘", "PR #N"                           |

확실히 위임하려면 `<이름>로 처리해줘`. 키워드가 맞으면 메인 Claude 가 한 줄로 위임을 제안한다.

## 명령 (`.claude/commands/`)

- `/pr [제목]` — 이슈 번호 확정 → 빌드·테스트 검증 → 푸시 → PR 생성(`Closes #N`) → 시니어 리뷰 → 감시 루프 제안
- `/new-feature <#N | 설명>` — 이슈 확정(없으면 생성) → `origin/main` 에서 `<type>/<N>-<이름>` worktree 생성 → xcodegen → subagent 위임
- `/cleanup-worktree [name]` — PR 머지 확인 후 worktree·브랜치 정리
- `/version-bump <major|minor|patch|x.y.z>` — project.yml 의 버전·빌드 번호 올리기

전역 명령(`/board`·`/study`·`/waiting`)은 그대로 쓴다.

## 루프·스케줄

세션 안은 `/loop`, 세션 밖(클라우드 routine)은 `/schedule`. 어느 것도 메시지를 보내지 않고 표시만 한다.

| 언제            | 명령                                                                                                                                         | 하는 일                         |
| --------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------- |
| 작업 세션 시작  | `/loop 1d /waiting list --overdue`                                                                                                           | 회신 대기 원장 기한 지난 것 표시 |
| PR 올린 뒤      | `/loop 10m PR #<N> 감시: gh pr checks <N> 와 새 리뷰 코멘트를 확인해 CI 실패·새 코멘트가 있을 때만 알려라. 체크 0개는 실패가 아니다. 머지되면 루프를 끝내라` | `/pr` 이후 감시                 |
| 심사 제출 뒤    | `/loop 30m App Store Connect 심사 상태를 확인하라고 알려라`                                                                                  | API 토큰이 없어 리마인드만      |

## Worktree 병렬 작업

- 위치 `.claude/worktrees/<name>/` (gitignore), 브랜치는 `origin/main` 최신에서 딴다(`git fetch` 먼저).
- **메인 워킹트리의 브랜치는 건드리지 않는다.** 같은 레포를 세션 여럿이 쓴다. 브랜치·worktree 에 손대기 전 `ListAgents` 로 busy 세션을 확인한다.
- worktree 를 만들면 그 안에서 `xcodegen generate` 를 돌린다(xcodeproj 가 따라오지 않는다).
- `guard-worktree.sh` 가 worktree 안에서 메인 레포 파일 수정을 차단한다.
