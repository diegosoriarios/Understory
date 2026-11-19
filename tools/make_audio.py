#!/usr/bin/env python3
"""Synthesises the game's sound effects and looping music into Assets/Audio/."""
import math
import random
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "Assets/Audio"
SR = 22050

random.seed(7)


def buf(dur):
    return [0.0] * int(SR * dur)


def add(dst, at, samples, gain=1.0):
    i = int(at * SR)
    for j, s in enumerate(samples):
        if 0 <= i + j < len(dst):
            dst[i + j] += s * gain


def env(n, attack=0.004, decay=0.18):
    a = max(1, int(attack * SR))
    out = []
    for i in range(n):
        e = i / a if i < a else math.exp(-(i - a) / (decay * SR))
        out.append(e)
    return out


def osc(freq, dur, kind="sine", vol=0.4, decay=0.18):
    n = int(SR * dur)
    e = env(n, decay=decay)
    out = []
    ph = 0.0
    for i in range(n):
        ph += 2 * math.pi * freq / SR
        if kind == "sine":
            v = math.sin(ph)
        elif kind == "square":
            v = 1.0 if math.sin(ph) >= 0 else -1.0
        elif kind == "saw":
            v = 2.0 * ((ph / (2 * math.pi)) % 1.0) - 1.0
        else:
            v = 2.0 * abs(2.0 * ((ph / (2 * math.pi)) % 1.0) - 1.0) - 1.0
        out.append(v * vol * e[i])
    return out


def sweep(f0, f1, dur, kind="square", vol=0.4, decay=0.15):
    n = int(SR * dur)
    out = []
    ph = 0.0
    for i in range(n):
        t = i / n
        f = f0 + (f1 - f0) * t
        ph += 2 * math.pi * f / SR
        if kind == "square":
            v = 1.0 if math.sin(ph) >= 0 else -1.0
        elif kind == "saw":
            v = 2.0 * ((ph / (2 * math.pi)) % 1.0) - 1.0
        else:
            v = math.sin(ph)
        e = math.exp(-i / (decay * SR))
        out.append(v * vol * e)
    return out


def noise(dur, vol=0.4, decay=0.15, smooth=0.5):
    n = int(SR * dur)
    out = []
    prev = 0.0
    for i in range(n):
        x = random.uniform(-1, 1)
        prev += smooth * (x - prev)
        out.append(prev * vol * math.exp(-i / (decay * SR)))
    return out


def sweep_noise(f0, f1, dur, vol=0.5, smooth=0.7):
    n = int(SR * dur)
    out = []
    ph = 0.0
    prev = 0.0
    for i in range(n):
        t = i / n
        f = f0 + (f1 - f0) * t
        ph += 2 * math.pi * f / SR
        prev += smooth * (random.uniform(-1, 1) - prev)
        e = math.exp(-i / (dur * 0.35 * SR))
        out.append((prev * 0.6 + math.sin(ph) * 0.4) * vol * e)
    return out


def kick(dur=0.18, vol=0.5):
    n = int(SR * dur)
    out = []
    ph = 0.0
    for i in range(n):
        t = i / n
        f = 120 - 80 * t
        ph += 2 * math.pi * f / SR
        out.append(math.sin(ph) * vol * math.exp(-i / (0.05 * SR)))
    return out


def save(name, data, peak=0.85, fade_in=0.0, fade_out=0.0):
    m = max(1e-9, max(abs(x) for x in data))
    n = len(data)
    raw = bytearray()
    for i, x in enumerate(data):
        v = x / m * peak
        if fade_in:
            v *= min(1.0, i / (fade_in * SR))
        if fade_out:
            v *= min(1.0, (n - i) / (fade_out * SR))
        v = max(-1.0, min(1.0, v))
        raw += struct.pack("<h", int(v * 32767))
    with wave.open(str(OUT / name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(bytes(raw))


def sfx():
    b = buf(0.16)
    add(b, 0.0, sweep(900, 160, 0.12, "square", 0.35, 0.09))
    add(b, 0.0, noise(0.1, 0.4, 0.05, 0.8))
    save("shoot.wav", b, 0.7)

    b = buf(0.12)
    add(b, 0.0, sweep(420, 130, 0.09, "square", 0.45, 0.06))
    add(b, 0.0, noise(0.06, 0.3, 0.03, 0.6))
    save("hit.wav", b, 0.6)

    b = buf(0.22)
    add(b, 0.0, sweep(320, 90, 0.16, "saw", 0.4, 0.1))
    add(b, 0.0, osc(720, 0.05, "square", 0.2, 0.03))
    save("bosshit.wav", b, 0.6)

    b = buf(0.35)
    add(b, 0.0, sweep(260, 70, 0.3, "saw", 0.45, 0.18))
    add(b, 0.0, noise(0.18, 0.15, 0.08, 0.3))
    save("hurt.wav", b, 0.7)

    b = buf(0.6)
    add(b, 0.0, sweep(300, 50, 0.55, "saw", 0.5, 0.35))
    add(b, 0.15, sweep(220, 40, 0.4, "square", 0.25, 0.3))
    save("death.wav", b, 0.75)

    b = buf(0.5)
    for i, f in enumerate([880.0, 1108.7, 1318.5, 1760.0]):
        add(b, i * 0.08, osc(f, 0.3, "sine", 0.35, 0.22))
    save("pickup.wav", b, 0.7)

    b = buf(0.5)
    add(b, 0.0, osc(1318.5, 0.35, "sine", 0.35, 0.25))
    add(b, 0.06, osc(1975.5, 0.35, "sine", 0.28, 0.25))
    save("key.wav", b, 0.7)

    b = buf(0.16)
    add(b, 0.0, sweep(330, 620, 0.11, "square", 0.4, 0.07))
    save("jump.wav", b, 0.6)

    b = buf(0.18)
    add(b, 0.0, sweep(440, 820, 0.12, "square", 0.4, 0.07))
    add(b, 0.0, noise(0.05, 0.2, 0.03, 0.7))
    save("walljump.wav", b, 0.65)

    b = buf(0.55)
    add(b, 0.0, noise(0.5, 0.7, 0.28, 0.22))
    add(b, 0.0, sweep_noise(200, 40, 0.5, 0.5, 0.25))
    add(b, 0.0, kick(0.3, 0.5))
    save("explosion.wav", b, 0.75)

    b = buf(0.45)
    add(b, 0.0, osc(90, 0.12, "sine", 0.5, 0.08))
    add(b, 0.05, sweep(200, 110, 0.3, "saw", 0.18, 0.2))
    save("door.wav", b, 0.65)

    b = buf(0.6)
    for i, f in enumerate([659.3, 784.0, 987.8, 1318.5]):
        add(b, i * 0.1, osc(f, 0.35, "square", 0.22, 0.15))
    save("levelclear.wav", b, 0.6)

    b = buf(1.4)
    for i, f in enumerate([523.3, 659.3, 784.0, 1046.5]):
        add(b, i * 0.15, osc(f, 0.5, "square", 0.22, 0.22))
    add(b, 0.6, osc(523.3, 0.7, "sine", 0.2, 0.5))
    add(b, 0.6, osc(659.3, 0.7, "sine", 0.18, 0.5))
    add(b, 0.6, osc(784.0, 0.7, "sine", 0.18, 0.5))
    save("win.wav", b, 0.65)

    b = buf(0.08)
    add(b, 0.0, sweep(1400, 900, 0.05, "square", 0.35, 0.03))
    save("ui.wav", b, 0.5)


def music():
    bpm = 120.0
    beat = 60.0 / bpm
    bars = 8
    total = bars * 4 * beat
    b = buf(total)
    chords = [
        [220.00, 261.63, 329.63],
        [174.61, 220.00, 261.63],
        [130.81, 164.81, 196.00],
        [196.00, 246.94, 293.66],
    ]
    roots = [110.0, 87.31, 130.81, 98.0]
    for bar in range(bars):
        t0 = bar * 4 * beat
        chord = chords[bar % 4]
        root = roots[bar % 4]
        add(b, t0, osc(root, 0.45, "square", 0.16, 0.32))
        add(b, t0 + 2 * beat, osc(root * 1.5, 0.45, "square", 0.12, 0.3))
        for k in range(8):
            add(b, t0 + k * beat / 2, noise(0.03, 0.04, 0.02, 0.9))
        for k in (0, 2):
            add(b, t0 + k * beat, kick(0.18, 0.35))
        seq = [0, 1, 2, 1, 2, 0, 1, 2]
        for i, idx in enumerate(seq):
            if i == 3 or (bar % 4 == 3 and i > 5 and i % 2 == 0):
                continue
            add(b, t0 + i * beat / 2, osc(chord[idx] * 2, 0.24, "square", 0.09, 0.13))
    # trim to the loop length and soften the seam
    b = b[: int(total * SR)]
    save("music.wav", b, 0.55, fade_in=0.01, fade_out=0.02)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    sfx()
    music()
    print("wrote audio to", OUT.relative_to(ROOT))


if __name__ == "__main__":
    main()
