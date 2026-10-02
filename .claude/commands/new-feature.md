새 작업을 이슈 → worktree 브랜치 → subagent 로 진행한다(languageforest `/new-feature` 이식). 사용자 입력: $ARGUMENTS (`#이슈번호` 또는 작업 설명)

## 절차

0. **세션 충돌 확인**: `ListAgents` 로 busy 인 keysound 세션이 있는지 본다. 같은 작업을 하는 것으로 보이면 사용자에게 알리고 멈춘다. **메인 워킹트리의 브랜치는 건드리지 않는다** — 그래서 항상 worktree 를 판다.

1. **이슈 확정 — 작업 1개 = 이슈 1 + 브랜치 1 + PR 1**
   - `$ARGUMENTS` 에 `#N` 이 있으면 `gh issue view N --json number,title,state,labels` 로 확인한다. `CLOSED` 면 멈추고 묻는다.
   - 없으면 설명으로 **이슈부터 만든다**: `gh issue create --title "<타입 접두어 없는 제목>" --body "<배경·할 일 체크리스트>" --label <라벨> --assignee @me`. 라벨은 `feat`→`enhancement`, `fix`→`bug`, `docs`→`documentation`, `chore`·`refactor`→ 없음.
   - 이미 같은 일을 다루는 열린 이슈가 있는지 `gh issue list --state open --search "<키워드>"` 로 먼저 본다. 있으면 그 이슈를 쓸지 묻는다.

1-1. **이름 결정**: 작업 종류(`feat`/`fix`/`chore`/`refactor`/`docs`)와 **`<이슈번호>-<kebab-case>`**. 예: 이슈 #12 "축 미리듣기 화면" → `feat/12-switch-preview`, worktree 이름은 `12-switch-preview`. `/pr` 이 브랜치 이름에서 이슈 번호를 읽으므로 번호를 빼지 않는다.

2. **경로·base**

   ```bash
   REPO_ROOT="$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")"
   WORKTREE_PATH="$REPO_ROOT/.claude/worktrees/<name>"
   git fetch origin main
   ```

3. **worktree 생성 — `origin/main` 에서 직접 분기**

   ```bash
   git worktree add "$WORKTREE_PATH" -b <type>/<name> --no-track origin/main
   ```

   - 로컬 main 이 아니라 `origin/main` 에서 딴다(뒤처진 로컬에서 갈라지는 사고 방지).
   - `--no-track`: upstream 은 `/pr` 의 `git push -u` 가 잡는다.

4. **환경 준비**: xcodeproj 가 gitignore 라 따라오지 않는다.

   ```bash
   (cd "$WORKTREE_PATH" && xcodegen generate)
   ```

5. **subagent 실행**: `Agent` 툴, `subagent_type` 은 보통 `ios-dev`. prompt 템플릿(`<WORKTREE_PATH>` 에 실제 절대경로를 박는다):

   ```
   작업 디렉토리: <WORKTREE_PATH>
   브랜치: <type>/<name>

   반드시 위 worktree 안의 파일만 수정한다. 메인 레포 파일을 고치면 guard-worktree.sh 가 차단한다.

   이슈: #<N> (완료 조건에 이슈 본문의 체크리스트 포함)

   작업 내용:
   <요청을 자기완결적으로 — 관련 파일, 제약, 기대 결과>

   완료 조건:
   - xcodegen generate 후 시뮬레이터 빌드 통과
   - 바꾼 Packages/* 의 swift test 통과
   - 커밋: conventional 한국어, Co-Authored-By 금지
   - 실기기에서 확인해야 할 항목 목록을 보고에 포함
   ```

6. 이슈 번호·worktree 경로·브랜치명을 알리고 결과를 기다린다. 끝나면 `/pr`(브랜치 번호로 `Closes #N` 자동), 머지 후 `/cleanup-worktree <name>`.

## 주의

- 같은 브랜치명이 이미 있으면 `-b` 없이 `git worktree add "$WORKTREE_PATH" <type>/<name>`. 4단계는 그대로 한다.
