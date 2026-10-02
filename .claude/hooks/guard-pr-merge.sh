#!/bin/bash
# `gh pr merge ... --delete-branch` 를 차단한다.
#
# 왜 필요한가:
#   --delete-branch 는 머지 뒤 로컬 브랜치를 지우고 base(main)로 체크아웃한다. 그러면
#   1) 같은 레포를 쓰는 다른 세션의 메인 워킹트리 브랜치가 바뀌어 그쪽 커밋이 엉뚱한 곳에 얹힌다.
#   2) 로컬 base 를 pull 하는 단계에서 "Cannot fast-forward to multiple branches" 가 나와
#      머지 실패로 오판한다(languageforest 실제 사고. 원격 머지는 이미 끝난 상태였다).
#   원격 브랜치는 레포 설정(deleteBranchOnMerge)이 머지 때 자동으로 지우므로 이 옵션은
#   로컬 정리 용도뿐이다. 로컬은 `/cleanup-worktree` 로 지운다.
#
# 등록: .claude/settings.json 의 PreToolUse(matcher "Bash") — languageforest-client 에서 이식
#   { "type": "command", "command": ".claude/hooks/guard-pr-merge.sh" }

INPUT=$(cat)

# 빠른 사전 필터 — 'merge' 가 없으면 python 기동 없이 통과.
printf '%s' "$INPUT" | grep -q 'merge' || exit 0

CMD=$(printf '%s' "$INPUT" | python3 -c \
  "import json,sys; print(json.load(sys.stdin).get('tool_input', {}).get('command', ''))" \
  2>/dev/null)
[ -z "$CMD" ] && exit 0

# 명령 시작 위치(또는 ; & | ( 뒤)의 `gh pr merge` 만 본다. 문자열 안의 문구는 오탐하지 않는다.
PREFIX='(^|[;&|(])[[:space:]]*([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*'
MERGE_CMD=$(printf '%s' "$CMD" | grep -oE "${PREFIX}gh[[:space:]]+pr[[:space:]]+merge[^;&|]*" | head -1)
[ -z "$MERGE_CMD" ] && exit 0

# --delete-branch(=true) 또는 -d(묶음 단축 -sd 포함)가 있을 때만 차단. --delete-branch=false 는 통과.
printf '%s' "$MERGE_CMD" | grep -Eq '(^|[[:space:]])(--delete-branch(=true)?|-[A-Za-z]*d[A-Za-z]*)([[:space:]]|$)' || exit 0

python3 <<'PYEOF'
import json
print(json.dumps({
    'decision': 'block',
    'reason': (
        '`gh pr merge --delete-branch` 를 차단했습니다.\n\n'
        '이 옵션은 머지 뒤 로컬을 base 로 체크아웃해 ① 다른 세션이 쓰는 워킹트리 브랜치가 바뀌고 '
        '② 로컬 pull 단계의 "Cannot fast-forward" 에러가 머지 실패처럼 보입니다.\n'
        '원격 브랜치는 레포 설정이 머지 때 자동으로 지웁니다. 옵션을 빼고 다시 실행하고, '
        '로컬 브랜치·worktree 는 머지 후 `/cleanup-worktree <name>` 로 정리하세요.'
    )
}, ensure_ascii=False))
PYEOF
