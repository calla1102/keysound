#!/bin/bash
# PR 생성은 반드시 /pr 명령(스킬)을 경유하도록 강제한다. (languageforest-client 것을 이식)
# gh pr create 직접 호출을 차단하고, /pr 명령이 붙이는 마커(KS_PR_OK=1)가 있을 때만 통과시킨다.

INPUT=$(cat)

# 빠른 사전 필터: 'gh ... pr ... create' 흔적이 없으면 python 기동 없이 통과.
printf '%s' "$INPUT" | grep -Eq 'gh.{0,8}pr.{0,8}create' || exit 0

CMD=$(printf '%s' "$INPUT" | python3 -c \
  "import json,sys; print(json.load(sys.stdin).get('tool_input', {}).get('command', ''))" \
  2>/dev/null)
[ -z "$CMD" ] && exit 0

# 명령 위치(줄 시작 또는 ; && | ( 뒤, env 변수 접두어 허용)의 gh pr create 만 본다.
printf '%s' "$CMD" | grep -Eq '(^|[;&|(])[[:space:]]*([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*gh[[:space:]]+pr[[:space:]]+create' || exit 0

printf '%s' "$CMD" | grep -q 'KS_PR_OK=1' && exit 0

python3 <<'PYEOF'
import json
print(json.dumps({
    'decision': 'block',
    'reason': (
        'PR 생성은 /pr 명령(스킬)을 사용하세요. gh pr create 직접 호출은 차단됩니다. '
        '/pr 은 빌드·테스트 검증, conventional 한국어 제목, 시니어 리뷰까지 처리합니다. '
        '(예외적으로 직접 호출이 필요하면 /pr 절차에 따라 KS_PR_OK=1 마커를 붙이세요.)'
    )
}, ensure_ascii=False))
PYEOF
