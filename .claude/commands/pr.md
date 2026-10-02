현재 브랜치의 변경사항으로 PR 을 만든다(languageforest `/pr` 을 1인 Swift 프로젝트용으로 줄인 것 — 노션 태스크 번호·Copilot·출시 노션 정리는 없다). 사용자 입력: $ARGUMENTS

> `$ARGUMENTS` 에 제목이나 이슈 번호(`#12`)가 있으면 활용한다.
>
> **작업 1개 = GitHub 이슈 1 + 브랜치 1 + PR 1.** 브랜치 이름 `<type>/<이슈번호>-<이름>` 에서 이슈를 읽어 `Closes #N` 으로 묶는다.

## 절차

1. **브랜치/커밋 상태 확인**

   ```bash
   BRANCH="$(git rev-parse --abbrev-ref HEAD)"
   git status --short
   git fetch origin main
   git log --oneline origin/main..HEAD
   ```

   - 현재 브랜치가 `main` 이면 중단하고 작업 브랜치를 만들도록 안내한다.
   - 미커밋 변경이 있으면 커밋할지 사용자에게 확인한다. 임의 커밋 금지.

1-1. **이슈 번호 확정**

   ```bash
   ISSUE="$(printf '%s' "$BRANCH" | sed -nE 's#^[a-z]+/([0-9]+)-.*#\1#p')"
   [ -n "$ISSUE" ] && gh issue view "$ISSUE" --json number,title,state
   ```

   - 우선순위: `$ARGUMENTS` 의 `#N` > 브랜치 이름의 번호.
   - **둘 다 없으면** `gh issue list --state open --assignee @me` 로 후보를 보여주고 고르게 한다. 맞는 게 없으면 **그 자리에서 만든다** — 제목은 PR 제목에서 `타입:` 접두어를 뗀 것, 라벨은 6단계 매핑과 같은 값, `--assignee @me`.
   - 이슈가 `CLOSED` 면 멈추고 확인받는다.

2. **사전 검증** — 실패하면 멈추고 보고한다.

   ```bash
   xcodegen generate
   xcodebuild -project Keysound.xcodeproj -scheme Keysound \
     -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
   git diff --name-only "$(git merge-base origin/main HEAD)...HEAD" | sed -nE 's#^(Packages/[^/]+)/.*#\1#p' | sort -u
   # 위에서 나온 패키지마다
   (cd Packages/<패키지> && swift test)
   ```

3. **푸시**: `git push -u origin "$BRANCH"` (아직 안 했으면)

4. **제목**: conventional 한국어 — `feat: 두벌식 오토마타 추가`. 대괄호 타입·번호 접두어 없음.

5. **본문** (한국어, `--body-file` 로 전달):

   ```
   ## 변경 내용
   - …

   ## 검증
   - 시뮬레이터 빌드: 통과
   - swift test: <패키지> 통과 / 해당 없음
   - 실기기: <확인한 것> / 미확인 — <확인해야 할 것>

   Closes #<이슈>
   ```

   - **`Closes #<이슈>` 는 본문 맨 끝에 반드시 넣는다.** 없으면 `enforce-pr-skill.sh` 가 PR 생성을 차단한다. base 가 `main` 이라 머지 때 이슈가 자동으로 닫힌다.

   - `Generated with Claude Code` 류 푸터·Claude 언급 금지.
   - 키보드 UI·사운드·입력 로직을 바꿨으면 `keyboard-qa-reviewer` 를 돌려 실기기 체크리스트를 본문 「검증」에 붙인다.

6. **라벨**: 저장소 기본 라벨을 쓴다 — `feat:`→`enhancement`, `fix:`→`bug`, `docs:`→`documentation`, `chore:`·`refactor:`→ 라벨 없음. 이슈 라벨도 같은 매핑.

7. **PR 생성** — 반드시 `KS_PR_OK=1` 마커를 붙이고 본문은 `--body-file` 로 넘긴다(마커가 없거나 본문 파일에 `Closes #N` 이 없으면 훅이 차단).

   ```bash
   KS_PR_OK=1 gh pr create --base main --title "<타입>: <제목>" \
     --body-file <임시파일> --label "<라벨>" --assignee "@me"
   ```

8. **시니어 리뷰**: 바로 머지하지 않는다. `ios-tech-lead` 에 위임(또는 `/code-review high`)해 must-fix 는 수정·커밋·푸시하고, PR 에 셀프리뷰 코멘트(반영/이월 + 커밋 해시)를 남긴다. 머지 가능 상태까지만 만들고 **사용자 확인 후 머지**한다. PR URL 을 출력한다.

9. **감시 루프 제안**: `/loop 10m PR #<N> 감시: gh pr checks <N> 와 새 리뷰 코멘트를 확인해 CI 실패·새 코멘트가 있을 때만 알려라. 체크 0개는 실패가 아니다. 머지되면 루프를 끝내라`

   머지는 `gh pr merge <N> --squash` 만. `--delete-branch` 금지(훅 차단). 로컬 정리는 `/cleanup-worktree`.
