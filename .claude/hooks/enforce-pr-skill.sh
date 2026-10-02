#!/bin/bash
# PR 생성은 반드시 /pr 명령(스킬)을 경유하도록 강제한다. (languageforest-client 것을 이식)
# gh pr create 직접 호출을 차단하고, /pr 명령이 붙이는 마커(KS_PR_OK=1)가 있을 때만 통과시킨다.
# 마커가 있어도 PR 본문에 `Closes #N` 이 없으면 차단한다(작업 1개 = 이슈 1 + 브랜치 1 + PR 1).

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
  # `gh pr create` 뒤 인자의 본문(--body-file/-F, --body/-b)에서 `Closes #N` 을 찾는다.
  # 본문 파일 상대경로는 훅 입력의 cwd 기준으로 푼다. 셸 변수는 펼칠 수 없으므로 /pr 은 리터럴 절대경로를 쓴다.
  # 읽기 실패·예외는 모두 차단(fail-closed).
  export HOOK_INPUT="$INPUT"
  python3 <<'PYEOF'
import json, os, re, shlex

def block(reason):
    print(json.dumps({'decision': 'block', 'reason': reason}, ensure_ascii=False))

try:
    data = json.loads(os.environ.get('HOOK_INPUT', '{}'))
    cmd = data.get('tool_input', {}).get('command', '')
    cwd = data.get('cwd') or os.getcwd()
    try:
        args = shlex.split(cmd)
    except ValueError:
        args = cmd.split()

    # `gh pr create` 뒤의 인자만 본다(앞의 `git commit -F` 같은 다른 명령 인자 오인 방지).
    start = None
    for i in range(len(args) - 2):
        if args[i:i + 3] == ['gh', 'pr', 'create']:
            start = i + 3
            break
    if start is None:
        raise ValueError('gh pr create 토큰을 찾지 못함')
    rest = []
    for a in args[start:]:
        if a in (';', '&&', '||', '|'):
            break
        rest.append(a)

    def read(path):
        path = os.path.expanduser(path)
        if not os.path.isabs(path):
            path = os.path.join(cwd, path)
        with open(path, encoding='utf-8', errors='replace') as f:
            return f.read()

    body = ''
    for i, a in enumerate(rest):
        nxt = rest[i + 1] if i + 1 < len(rest) else None
        if a in ('--body-file', '-F') and nxt is not None:
            body += read(nxt)
        elif a.startswith('--body-file='):
            body += read(a.split('=', 1)[1])
        elif a in ('--body', '-b') and nxt is not None:
            body += nxt
        elif a.startswith('--body='):
            body += a.split('=', 1)[1]

    if not re.search(r'(?i)\b(closes|fixes|resolves)\s+#\d+', body):
        block(
            'PR 본문에 `Closes #<이슈번호>` 가 없습니다. 작업 1개 = 이슈 1 + 브랜치 1 + PR 1 규칙입니다. '
            '브랜치 이름 `<type>/<N>-<이름>` 의 번호나 `/pr` 1-1단계에서 정한 이슈로 본문 맨 끝에 `Closes #N` 을 넣으세요. '
            '본문 파일은 PR 생성 전에 따로 만들고 리터럴 절대경로로 넘기세요.'
        )
except Exception as e:
    block(f'PR 본문을 확인하지 못해 차단했습니다({type(e).__name__}: {e}). 본문 파일을 리터럴 절대경로로 넘기세요.')
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
