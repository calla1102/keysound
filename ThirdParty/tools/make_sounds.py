"""원본 녹음(ThirdParty/<녹음자>/)에서 키보드 타건음 wav 를 만든다.

사용: python3 make_sounds.py <변환본 폴더> <출력 폴더>
  변환본 폴더에는 build_sounds.sh 가 ffmpeg 로 만든 모노 44.1kHz Int16 wav 가 있어야 한다.
  출력은 기존 규칙 `<축>_<press|release>_<generic_r0~4|generic|space|enter|backspace>.wav`.

공통 규칙
- 눌림 generic r2 피크 -7dBFS, 뗌은 일반 키보다 RMS -9dB, 스페이스·엔터·백스페이스는 일반 키 RMS +3dB 상한
- 모든 파일 3ms 페이드인, 끝 페이드아웃(길이별 6~15ms)
- 축별 자세한 선택 근거는 ThirdParty/CREDITS.md
"""
import glob
import os
import sys
import wave

import numpy as np

SR = 44100
SRC, OUT = sys.argv[1], sys.argv[2]


# ---------- 공통 ----------
def read(path):
    with wave.open(path) as w:
        assert (w.getnchannels(), w.getframerate(), w.getsampwidth()) == (1, SR, 2), (path, w.getparams())
        return np.frombuffer(w.readframes(w.getnframes()), dtype="<i2").astype(float) / 32768


def env_db(x, ms=3):
    n = max(1, int(SR * ms / 1000))
    return 10 * np.log10(np.convolve(x ** 2, np.ones(n) / n, "same") + 1e-12)


def onset_list(x, rise=15, gap=0.04):
    """바닥보다 22dB 위이면서 직전 20ms 최소보다 rise dB 급상승한 지점(잔향 꼬리 제외)."""
    e = env_db(x)
    thr = max(np.percentile(e, 20), -90) + 22
    look = int(SR * 0.02)
    on, i = [], look
    while i < len(e):
        if e[i] > thr and e[i] - e[i - look:i].min() > rise:
            on.append(max(0, i - int(SR * 0.004)))
            i += int(SR * gap)
        else:
            i += 1
    return on


def split_hits(x, press_len=0.11, rel_len=0.07):
    """연속 녹음을 (눌림, 뗌 또는 None) 쌍으로 나눈다. 뗌 = 50~160ms 뒤의 5dB 이상 작은 소리."""
    e = env_db(x)
    thr = np.percentile(e, 20) + 28
    look = int(SR * 0.02)
    onsets, i = [], look
    while i < len(e):
        if e[i] > thr and e[i] - e[i - look:i].min() > 15:
            onsets.append(max(0, i - int(SR * 0.004)))
            i += int(SR * 0.04)
        else:
            i += 1
    peaks = [e[o:o + int(SR * 0.03)].max() for o in onsets]
    pairs, used = [], set()
    for k, (o, p) in enumerate(zip(onsets, peaks)):
        if k in used:
            continue
        rel = None
        if k + 1 < len(onsets):
            dt = (onsets[k + 1] - o) / SR
            if 0.05 <= dt <= 0.16 and peaks[k + 1] < p - 5:
                rel = onsets[k + 1]
                used.add(k + 1)
        pl = int(SR * press_len) if rel is None else min(int(SR * press_len), rel - o)
        press = x[o:o + pl]
        release = x[rel:rel + int(SR * rel_len)] if rel is not None else None
        if len(press) > int(SR * 0.04):
            pairs.append((press, release))
    return pairs


def resample(x, ratio):
    """ratio>1 이면 높아지고 짧아진다(선형 보간)."""
    n = int(len(x) / ratio)
    return np.interp(np.linspace(0, len(x) - 1, n), np.arange(len(x)), x)


def finish(x, max_ms, fade_ms=6):
    x = x[: int(SR * max_ms / 1000)].copy()
    f = min(len(x) // 3, int(SR * fade_ms / 1000))
    x[-f:] *= np.linspace(1, 0, f)
    fi = int(SR * 0.003)
    x[:fi] *= np.linspace(0, 1, fi)
    return x


def rms(v):
    return np.sqrt((v[: int(SR * 0.04)] ** 2).mean()) + 1e-12


def save(prefix, files):
    ref = files["press_generic_r2"]
    gain = 10 ** (-7 / 20) / np.abs(ref).max()
    ref_rms = rms(ref) * gain
    for k, v in files.items():
        y = v * gain
        if k.startswith("release"):
            y = y * (ref_rms * 10 ** (-9 / 20)) / rms(y)
        elif not k.startswith("press_generic"):
            cap = ref_rms * 10 ** (3 / 20)
            if rms(y) > cap:
                y = y * cap / rms(y)
        if np.abs(y).max() > 0.95:
            y = y * 0.95 / np.abs(y).max()
        with wave.open(os.path.join(OUT, f"{prefix}_{k}.wav"), "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(SR)
            w.writeframes((np.clip(y, -1, 1) * 32767).astype("<i2").tobytes())
    print(prefix + ":", {k: round(len(v) / SR * 1000) for k, v in files.items()})


# ---------- 잡음 제거(스펙트럼 차감, 최대 20dB) ----------
_N, _H = 1024, 256
_WIN = np.hanning(_N + 1)[:-1]


def _stft(x):
    pad = np.concatenate([np.zeros(_N // 2), x, np.zeros(_N)])
    return np.fft.rfft(np.lib.stride_tricks.sliding_window_view(pad, _N)[::_H] * _WIN, axis=1)


def _istft(S, L):
    fr = np.fft.irfft(S, _N, axis=1) * _WIN
    out = np.zeros(_N // 2 + L + 2 * _N)
    nrm = np.zeros_like(out)
    for i, f in enumerate(fr):
        out[i * _H:i * _H + _N] += f
        nrm[i * _H:i * _H + _N] += _WIN ** 2
    return (out / np.maximum(nrm, 1e-3))[_N // 2:_N // 2 + L]


def denoise(x, strength_db=14):
    S = _stft(x)
    M = np.abs(S)
    e = M.sum(1)
    q = M[e <= np.percentile(e, 15)].mean(0) + 1e-9  # 조용한 프레임 15% 의 평균 = 잡음 프로필
    g = np.clip(1 - q * 10 ** (strength_db / 20) / (M + 1e-9), 0, 1)
    g = np.maximum(g, 10 ** (-20 / 20))
    g = np.maximum(g, 0.5 * np.roll(g, 1, 0) + 0.5 * np.roll(g, -1, 0))
    return _istft(S * g, len(x))


def first_onset(x, rise=10):
    e = env_db(x)
    thr = max(np.percentile(e, 20), -90) + 22
    look = int(SR * 0.02)
    for i in range(look, len(e)):
        if e[i] > thr and e[i] - e[i - look:i].min() > rise:
            return max(0, i - int(SR * 0.004))
    return 0


def cut_at(x, start, ms):
    return x[start:start + int(SR * ms / 1000)]


os.makedirs(OUT, exist_ok=True)

# ---------- 적축 (Sadiquecat, Keychron K10) ----------
red = split_hits(read(f"{SRC}/red_keys.wav"))
space = split_hits(read(f"{SRC}/red_space.wav"))[0]
enter = split_hits(read(f"{SRC}/red_enter.wav"))[0]
with_rel = sorted([p for p in red if p[1] is not None], key=lambda p: -np.abs(p[0]).max())
press5 = [p[0] for p in with_rel[:5]]
rel = with_rel[0][1]
files = {f"press_generic_r{r}": finish(press5[r], 110) for r in range(5)}
files["release_generic"] = finish(rel, 70)
files["press_space"], files["release_space"] = finish(space[0], 130), finish(space[1] if space[1] is not None else rel, 70)
files["press_enter"], files["release_enter"] = finish(enter[0], 120), finish(enter[1] if enter[1] is not None else rel, 70)
files["press_backspace"] = finish(resample(press5[1], 0.96), 115)
files["release_backspace"] = finish(rel, 70)
save("red", files)

# ---------- 갈축 (Foxfire-) ----------
bp = split_hits(read(f"{SRC}/brown_press.wav"))[0][0]
# 뗌: Foxfire- 뗌 녹음(570755)은 '휙' 하는 바람 잡음이라 쓰지 않고, 눌림을 1.6배 높고 짧게 깎아 '틱' 으로 만든다
tick = resample(bp, 1.6)
files = {f"press_generic_r{r}": finish(resample(bp, 1 + (r - 2) * 0.0125), 70, fade_ms=15) for r in range(5)}
files["release_generic"] = finish(tick, 35, fade_ms=12)
files["press_space"], files["release_space"] = finish(resample(bp, 0.90), 80, fade_ms=15), finish(resample(bp, 1.45), 40, fade_ms=12)
files["press_enter"], files["release_enter"] = finish(resample(bp, 0.94), 80, fade_ms=15), finish(tick, 35, fade_ms=12)
files["press_backspace"], files["release_backspace"] = finish(resample(bp, 0.97), 70, fade_ms=15), finish(tick, 35, fade_ms=12)
save("brown", files)

# ---------- 청축 (UberBosser, 폰 녹음) : 일반 키만 ----------
clips = {k: read(f"{SRC}/blue_{i}.wav") for k, i in dict(w=421581, space=421582, q=421583, ctrl=421584).items()}
bw, bq, bc, bs = clips["w"], clips["q"], clips["ctrl"], clips["space"]
w_on, q_on, c_on, s_on = (first_onset(v) for v in (bw, bq, bc, bs))
presses = [cut_at(bw, w_on, 95), cut_at(bq, q_on, 95), cut_at(bc, c_on, 95), cut_at(bs, s_on, 60), resample(cut_at(bw, w_on, 95), 1.03)]
w_rel = onset_list(bw, rise=10, gap=0.03)
rel = cut_at(bw, w_rel[1], 60) if len(w_rel) > 1 else resample(presses[0], 1.6)
files = {f"press_generic_r{r}": finish(presses[r], 70, fade_ms=15) for r in range(5)}
files["release_generic"] = finish(rel, 45, fade_ms=12)
save("blue", files)

# ---------- 흑축 (el_boss Gateron, 연속 녹음 + 잡음 제거) ----------
# 온셋은 원본에서 찾고(잡음 제거본은 바닥이 너무 낮아 검출이 흔들린다), 자르기는 잡음 제거본에서 한다
raw = read(f"{SRC}/black_elboss.wav")
bx = denoise(raw)
ons = onset_list(raw, rise=15, gap=0.035)
peak = lambda o: float(np.abs(raw[o:o + int(SR * 0.03)]).max())
loud = [o for o in ons if 20 * np.log10(peak(o) + 1e-9) > -28]
cands = []
for o in loud:
    nxt = [n for n in ons if o < n <= o + int(SR * 0.12)]
    if any(n in loud for n in nxt):  # 120ms 안에 다른 눌림이 겹치면 제외
        continue
    rel = next((n for n in nxt if n >= o + int(SR * 0.04) and peak(n) < peak(o) * 0.5), None)
    cands.append((o, rel))
cands.sort(key=lambda c: -peak(c[0]))
cands = [c for c in cands if peak(c[0]) < 0.9][:8]
assert len(cands) >= 5, f"흑축: 겹치지 않는 눌림이 {len(cands)}개뿐이라 r0~r4 를 못 채운다 — 원본·임계값 확인"
# 후보 8개 중 시작이 깨끗한(첫 1ms 가 작은) 5개를 고르고, 눌림끼리 RMS 를 맞춘다
cands.sort(key=lambda c: float(np.abs(bx[c[0]:c[0] + 44]).max()))
press5 = [bx[o:o + int(SR * 0.09)] for o, _ in cands[:5]]
ref_r = rms(press5[0])
press5 = [v * ref_r / rms(v) for v in press5]
rels = [bx[r:r + int(SR * 0.06)] for _, r in cands if r is not None]
rel = rels[0] if rels else resample(press5[0], 1.6)
files = {f"press_generic_r{r}": finish(press5[r], 70, fade_ms=15) for r in range(5)}
files["release_generic"] = finish(rel, 40, fade_ms=12)
files["press_space"], files["release_space"] = finish(resample(press5[0], 0.90), 80, fade_ms=15), finish(resample(rel, 0.95), 45, fade_ms=12)
files["press_enter"], files["release_enter"] = finish(resample(press5[1], 0.94), 80, fade_ms=15), finish(rel, 40, fade_ms=12)
files["press_backspace"], files["release_backspace"] = finish(resample(press5[2], 0.97), 70, fade_ms=15), finish(rel, 40, fade_ms=12)
save("black", files)

# ---------- 무접점 (MakotoHiramatsu HHKB, CC BY 4.0) ----------
topre = []
for f in sorted(glob.glob(f"{SRC}/topre_*.wav")):
    x = read(f)
    on = onset_list(x, rise=15, gap=0.04)
    if not on:
        continue
    p = on[0]
    # 눌림 뒤 150ms 안에 또 큰 소리가 있으면(바운스·겹침) 제외
    if any(p < o < p + int(SR * 0.15) and np.abs(x[o:o + 1300]).max() > np.abs(x[p:p + 1300]).max() * 0.35 for o in on[1:]):
        continue
    rel_on = [o for o in on[1:] if p + int(SR * 0.15) <= o <= p + int(SR * 0.5)]
    topre.append((os.path.basename(f), x[p:p + int(SR * 0.1)], x[rel_on[0]:rel_on[0] + int(SR * 0.06)] if rel_on else None))
print("topre 사용 파일:", [t[0] for t in topre])
assert len(topre) >= 5, f"무접점: 깨끗한 파일이 {len(topre)}개뿐이라 r0~r4 를 못 채운다 — 원본·임계값 확인"
press5 = [t[1] for t in topre[:5]]
rels = [t[2] for t in topre if t[2] is not None]
rel = rels[0] if rels else resample(press5[0], 1.6)
extra = [t[1] for t in topre[5:8]] or press5
files = {f"press_generic_r{r}": finish(press5[r], 75, fade_ms=15) for r in range(5)}
files["release_generic"] = finish(rel, 45, fade_ms=12)
files["press_space"], files["release_space"] = finish(resample(extra[0], 0.90), 85, fade_ms=15), finish(resample(rel, 0.95), 50, fade_ms=12)
files["press_enter"], files["release_enter"] = finish(resample(extra[1 % len(extra)], 0.94), 85, fade_ms=15), finish(rel, 45, fade_ms=12)
files["press_backspace"], files["release_backspace"] = finish(resample(extra[2 % len(extra)], 0.97), 75, fade_ms=15), finish(rel, 45, fade_ms=12)
save("topre", files)
