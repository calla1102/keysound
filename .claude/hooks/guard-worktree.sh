#!/bin/bash
# 워크트리 모드에서 원본 레포 소스 코드 수정 차단
# PWD가 워크트리 서브디렉토리인 경우, 메인 레포의 파일 수정을 막는다

# 메인 레포 루트 계산:
# git --git-common-dir은 worktree 내부에서 호출해도 메인 레포의 .git을 반환.
# 스크립트 위치 기준(-C)으로 호출해 PWD 영향을 받지 않도록 한다.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GIT_COMMON_DIR="$(git -C "$SCRIPT_DIR" rev-parse --git-common-dir 2>/dev/null)"
[ -z "$GIT_COMMON_DIR" ] && exit 0  # git 환경 아니면 통과 (안전 fallback)

# 상대경로일 수 있으므로 SCRIPT_DIR 기준으로 절대경로화 후 dirname
case "$GIT_COMMON_DIR" in
  /*) ;;
  *) GIT_COMMON_DIR="$SCRIPT_DIR/$GIT_COMMON_DIR" ;;
esac
MAIN_REPO="$(cd "$(dirname "$GIT_COMMON_DIR")" && pwd)"

# 파일 경로: 환경변수 우선, 없으면 stdin JSON 파싱
# NotebookEdit는 notebook_path, 그 외는 file_path 사용
FILE_PATH="${CLAUDE_TOOL_INPUT_FILE_PATH:-}"
if [ -z "$FILE_PATH" ]; then
  FILE_PATH=$(cat | python3 -c \
    "import json,sys
d = json.load(sys.stdin).get('tool_input', {})
print(d.get('file_path') or d.get('notebook_path') or '')" \
    2>/dev/null)
fi

# 파일 경로 없으면 통과
[ -z "$FILE_PATH" ] && exit 0

# 메인 레포 루트에서 실행 중이면 워크트리 모드 아님 → 통과
[ "$PWD" = "$MAIN_REPO" ] && exit 0

# 메인 레포 하위 디렉토리가 아니면 통과
[[ "$PWD" != "$MAIN_REPO/"* ]] && exit 0

# 여기까지 오면 워크트리 내부에서 실행 중
# 파일이 메인 레포에 속하지만 현재 워크트리 바깥이면 차단
if [[ "$FILE_PATH" == "$MAIN_REPO/"* ]] && [[ "$FILE_PATH" != "$PWD/"* ]]; then
  HOOK_FILE_PATH="$FILE_PATH" HOOK_WT_PWD="$PWD" python3 <<'PYEOF'
import os, json
print(json.dumps({
    'decision': 'block',
    'reason': (
        '워크트리 모드 위반: 원본 레포 소스 코드를 직접 수정할 수 없습니다. '
        '차단된 파일=' + os.environ['HOOK_FILE_PATH'] + ' | '
        '현재 워크트리=' + os.environ['HOOK_WT_PWD'] + ' | '
        '워크트리 디렉토리 내 파일만 수정하세요.'
    )
}, ensure_ascii=False))
PYEOF
fi
