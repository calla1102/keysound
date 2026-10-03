"""「기본 클릭」 타건음(click_press.wav)을 합성한다. 외부 녹음을 쓰지 않는다.

40ms, 모노 44.1kHz Int16. 2.5kHz 감쇠 사인(틱) + 1~6kHz 대역 잡음 버스트(탁), 끝 6ms 페이드.
난수 시드를 고정해 항상 같은 바이트가 나온다. 사용: python3 make_click.py <출력 wav>
"""
import sys
import wave

import numpy as np

SR = 44100
n = int(SR * 0.040)
t = np.arange(n) / SR
rng = np.random.default_rng(20261003)

tone = np.sin(2 * np.pi * 2500 * t) * np.exp(-t / 0.004)
spec = np.fft.rfft(rng.standard_normal(n))
f = np.fft.rfftfreq(n, 1 / SR)
spec[(f < 1000) | (f > 6000)] = 0
noise = np.fft.irfft(spec, n)
noise = noise / np.abs(noise).max() * np.exp(-t / 0.003)

x = 0.7 * tone + 0.6 * noise
x[: int(SR * 0.0005)] *= np.linspace(0, 1, int(SR * 0.0005))
fade = int(SR * 0.006)
x[-fade:] *= np.linspace(1, 0, fade)
x = x / np.abs(x).max() * 10 ** (-7 / 20)

with wave.open(sys.argv[1], "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes((x * 32767).astype("<i2").tobytes())
