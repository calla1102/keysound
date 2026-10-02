#!/bin/bash
# 커밋 전 빌드·테스트를 강제한다. (languageforest-client 의 enforce-tsc.sh 를 Swift 용으로 바꾼 것)
#
# 왜 필요한가:
#   Swift 는 eslint·tsc 같은 가벼운 검사가 없고, 컴파일 에러는 빌드해야만 드러난다.
#   xcodeproj 가 gitignore 라 project.yml 을 바꾸고 재생성을 잊으면 다른 세션·worktree 에서 깨진다.
#
# 하는 일 (커밋 명령일 때만):
#   1. 작업 트리에 Swift·project.yml·Package.swift·리소스 변경이 없으면 통과(문서만 바꾼 커밋)
#   2. 바뀐 Packages/<이름> 마다 `swift test`
#   3. `xcodegen generate` 후 시뮬레이터 대상 `xcodebuild build` (서명 없이)
#   하나라도 실패하면 커밋 차단.
#
# 우회: 커밋 명령 앞에 SKIP_BUILD=1 (명령 접두 위치에서만 인정)

INPUT=$(cat)
printf '%s' "$INPUT" | grep -q 'commit' || exit 0

CMD=$(printf '%s' "$INPUT" | python3 -c \
  "import json,sys; print(json.load(sys.stdin).get('tool_input', {}).get('command', ''))" \
  2>/dev/null)
[ -z "$CMD" ] && exit 0

PREFIX='(^|[;&|(])[[:space:]]*([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*'
printf '%s' "$CMD" | grep -Eq "${PREFIX}git[[:space:]]+(-C[[:space:]]+[^[:space:]]+[[:space:]]+)?commit" || exit 0
printf '%s' "$CMD" | grep -Eq "${PREFIX}SKIP_BUILD=1" && exit 0

# `git -C <path>` 커밋이면 그 경로에서 검사한다.
GIT_C_CMD=$(printf '%s' "$CMD" | grep -oE "${PREFIX}git[[:space:]]+-C[[:space:]]+[^[:space:]]+[[:space:]]+commit" | head -1)
TARGET_DIR=$(printf '%s' "$GIT_C_CMD" | sed -nE 's/.*-C[[:space:]]+([^[:space:]]+)[[:space:]]+commit$/\1/p')
[ -z "$TARGET_DIR" ] && TARGET_DIR="."
ROOT=$(git -C "$TARGET_DIR" rev-parse --show-toplevel 2>/dev/null) || exit 0
[ -f "$ROOT/project.yml" ] || exit 0

# 바뀐 파일(스테이징·미스테이징·untracked 모두). add 와 커밋을 한 줄로 잇는 경우도 잡도록 HEAD 기준.
CHANGED=$( { git -C "$ROOT" diff --name-only HEAD 2>/dev/null; git -C "$ROOT" ls-files --others --exclude-standard; } | sort -u)
printf '%s\n' "$CHANGED" | grep -Eq '\.swift$|project\.yml$|Package\.swift$|\.(plist|entitlements|wav)$|/Contents\.json$' || exit 0

FAIL=""
for PKG in $(printf '%s\n' "$CHANGED" | sed -nE 's#^(Packages/[^/]+)/.*#\1#p' | sort -u); do
  [ -f "$ROOT/$PKG/Package.swift" ] || continue
  OUT=$(cd "$ROOT/$PKG" && swift test 2>&1)
  if [ $? -ne 0 ]; then
    FAIL+="■ $PKG swift test 실패"$'\n'"$(printf '%s\n' "$OUT" | grep -E 'error|failed|XCTAssert|Expectation' | head -15)"$'\n\n'
  fi
done

if command -v xcodegen >/dev/null 2>&1; then
  (cd "$ROOT" && xcodegen generate >/dev/null 2>&1) || FAIL+="■ xcodegen generate 실패 (project.yml 확인)"$'\n\n'
fi
DD="${TMPDIR:-/tmp}/keysound-hook-dd-$(printf '%s' "$ROOT" | shasum | cut -c1-8)"
SCHEME=$(sed -nE 's/^name:[[:space:]]*([A-Za-z0-9_-]+).*/\1/p' "$ROOT/project.yml" | head -1)
BUILD=$(cd "$ROOT" && xcodebuild -project "$SCHEME.xcodeproj" -scheme "$SCHEME" \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath "$DD" \
  CODE_SIGNING_ALLOWED=NO -quiet build 2>&1)
if [ $? -ne 0 ]; then
  FAIL+="■ xcodebuild 실패"$'\n'"$(printf '%s\n' "$BUILD" | grep -E 'error:' | head -15)"$'\n'
fi

[ -z "$FAIL" ] && exit 0

export FAIL
python3 <<'PYEOF'
import json, os
print(json.dumps({
    'decision': 'block',
    'reason': (
        '빌드·테스트가 실패해 커밋을 차단했습니다. 고친 뒤 다시 커밋하세요.\n\n'
        + os.environ.get('FAIL', '') +
        '\n(긴급 우회는 커밋 명령 앞에 SKIP_BUILD=1)'
    )
}, ensure_ascii=False))
PYEOF
