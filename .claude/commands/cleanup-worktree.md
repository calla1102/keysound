worktree 작업이 끝났을 때 정리한다(languageforest `/cleanup-worktree` 이식, base 는 main). 사용자 입력: $ARGUMENTS

## 절차

1. **대상·브랜치 확보**

   ```bash
   REPO_ROOT="$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")"
   WORKTREE_PATH="$REPO_ROOT/.claude/worktrees/<name>"
   BRANCH="$(git -C "$WORKTREE_PATH" rev-parse --abbrev-ref HEAD)"   # 추정하지 말고 조회
   ```

   - `$ARGUMENTS` 가 비면 `git worktree list` 를 보여주고 고르게 한다.
   - `ListAgents` 로 이 worktree 를 쓰는 busy 세션이 없는지 본다. 있으면 확인받고 진행.

2. **미커밋/미푸시 확인**

   ```bash
   git -C "$WORKTREE_PATH" status --short
   if git -C "$WORKTREE_PATH" fetch origin "$BRANCH" 2>/dev/null; then
     git -C "$WORKTREE_PATH" log "origin/$BRANCH..HEAD"
   else
     git -C "$WORKTREE_PATH" log origin/main..HEAD
     echo "ℹ️ 원격에 $BRANCH 가 없습니다 — 미푸시이거나 머지 뒤 자동 삭제(3단계로 판별)"
   fi
   ```

   미커밋·미푸시가 있으면 **반드시 사용자 확인.** 임의 폐기 금지.

3. **PR 머지 여부 — PR 상태가 정답**

   ```bash
   gh pr list --head "$BRANCH" --state all --json number,state,mergedAt
   ```

   squash 머지라 `git branch -d` 의 "미머지" 판정은 틀린다. 그걸로 판단하지 않는다.

4. **worktree 제거**: `git worktree remove "$WORKTREE_PATH"`. untracked(생성된 xcodeproj 등) 때문에 거부되면 목록을 보여주고 동의 시에만 `--force`. 디렉터리가 남으면 내용 확인 후 삭제.

5. **브랜치 삭제**: `MERGED` 확인 시 `git branch -D "$BRANCH"`. 아니면 사용자 확인 후에만. 원격 브랜치가 남아 있으면 확인 후 `git push origin --delete "$BRANCH"`.

6. **prune + 껍데기 검사**

   ```bash
   git worktree prune
   git worktree list
   ls -A "$REPO_ROOT/.claude/worktrees/"
   ```

## 주의

- 미머지 브랜치의 `-D`·`--force` 는 사용자 확인 없이 쓰지 않는다.
- `git stash` 를 쓰지 않는다 — stash 는 모든 worktree·세션이 공유한다.
