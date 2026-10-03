#!/bin/sh
# ThirdParty/ 의 원본 녹음에서 KeyboardExtension/Sounds/ 의 축별 wav 를 다시 만든다.
# 필요: ffmpeg, python3 + numpy. 결과는 결정적(난수 없음)이라 같은 원본이면 같은 바이트가 나온다.
set -eu
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TP="$ROOT/ThirdParty"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

conv() { ffmpeg -loglevel error -y -i "$1" -ac 1 -ar 44100 -sample_fmt s16 "$WORK/$2.wav"; }

conv "$TP/sadiquecat/789628__sadiquecat__keychron-k10-a-to-individual-keys.flac" red_keys
conv "$TP/sadiquecat/789630__sadiquecat__keychron-k10-space_bar.wav" red_space
conv "$TP/sadiquecat/789629__sadiquecat__keychron-k10-enter.wav" red_enter
conv "$TP/foxfire/570754__foxfire__keyboard-press-down.wav" brown_press
for f in "$TP"/uberbosser/4215*__uberbosser__*.wav; do
  b="$(basename "$f")"; conv "$f" "blue_${b%%__*}"
done
conv "$TP/el_boss/643559__el_boss__gateron-black-switches-sound.wav" black_elboss
for f in "$TP"/makotohiramatsu/KEY_PRESS_*.wav; do
  b="$(basename "$f" .wav)"; conv "$f" "topre_${b#KEY_PRESS_}"
done

python3 "$TP/tools/make_sounds.py" "$WORK" "$ROOT/KeyboardExtension/Sounds"
