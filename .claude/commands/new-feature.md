새 기능을 worktree 기반 subagent 로 진행한다(languageforest `/new-feature` 이식). 사용자 입력: $ARGUMENTS

## 절차

0. **세션 충돌 확인**: `ListAgents` 로 busy 인 keysound 세션이 있는지 본다. 같은 작업을 하는 것으로 보이면 사용자에게 알리고 멈춘다. **메인 워킹트리의 브랜치는 건드리지 않는다** — 그래서 항상 worktree 를 판다.

1. **이름 결정**: 작업 종류(`feat`/`fix`/`chore`/`refactor`)와 kebab-case 이름. 예: "축 미리듣기 화면" → `feat/switch-preview`. 애매하면 `feat`.

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

   작업 내용:
   <요청을 자기완결적으로 — 관련 파일, 제약, 기대 결과>

   완료 조건:
   - xcodegen generate 후 시뮬레이터 빌드 통과
   - 바꾼 Packages/* 의 swift test 통과
   - 커밋: conventional 한국어, Co-Authored-By 금지
   - 실기기에서 확인해야 할 항목 목록을 보고에 포함
   ```

6. worktree 경로·브랜치명을 알리고 결과를 기다린다. 끝나면 `/pr`, 머지 후 `/cleanup-worktree <name>`.

## 주의

- 같은 브랜치명이 이미 있으면 `-b` 없이 `git worktree add "$WORKTREE_PATH" <type>/<name>`. 4단계는 그대로 한다.
