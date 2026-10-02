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

if printf '%s' "$CMD" | grep -q 'KS_PR_OK=1'; then
  # 작업 1개 = 이슈 1 + 브랜치 1 + PR 1. 본문(--body-file 또는 --body)에 `Closes #N` 이 있어야 통과.
  export CMD
  python3 <<'PYEOF'
import json, os, re, shlex, sys
cmd = os.environ.get('CMD', '')
try:
    args = shlex.split(cmd)
except ValueError:
    args = cmd.split()
body = ''
for i, a in enumerate(args):
    if a in ('--body-file', '-F') and i + 1 < len(args):
        try:
            body += open(os.path.expanduser(args[i + 1]), encoding='utf-8').read()
        except OSError:
            pass
    elif a.startswith('--body-file='):
        try:
            body += open(os.path.expanduser(a.split('=', 1)[1]), encoding='utf-8').read()
        except OSError:
            pass
    elif a in ('--body', '-b') and i + 1 < len(args):
        body += args[i + 1]
    elif a.startswith('--body='):
        body += a.split('=', 1)[1]
if re.search(r'(?i)\b(closes|fixes|resolves)\s+#\d+', body):
    sys.exit(0)
print(json.dumps({
    'decision': 'block',
    'reason': (
        'PR 본문에 `Closes #<이슈번호>` 가 없습니다. 작업 1개 = 이슈 1 + 브랜치 1 + PR 1 규칙입니다. '
        '브랜치 이름 `<type>/<N>-<이름>` 의 번호나 `/pr` 1-1단계에서 정한 이슈로 본문 맨 끝에 `Closes #N` 을 넣으세요.'
    )
}, ensure_ascii=False))
PYEOF
  exit 0
fi

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
