"""Generate placeholder sound effects and a music loop for Milo.

Pure standard-library Python (no numpy). Produces 16-bit mono WAVs in
assets/audio/sfx/ and assets/audio/music/. These are deliberately simple
chip-style sounds so the game has audio from day one; replace any of them
by dropping a file with the same name into the folder.

    python tools/generate_placeholder_audio.py
"""
import math
import os
import random
import struct
import wave

RATE = 22050
ROOT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "audio")


# --- tiny synth ----------------------------------------------------------

def sine(t, f):
    return math.sin(2 * math.pi * f * t)


def square(t, f):
    return 1.0 if (f * t) % 1.0 < 0.5 else -1.0


def triangle(t, f):
    x = (f * t) % 1.0
    return 4 * abs(x - 0.5) - 1


def saw(t, f):
    return 2 * ((f * t) % 1.0) - 1


def noise(_t, _f):
    return random.uniform(-1, 1)


def env(t, attack, decay, length):
    """Attack-then-exponential-decay envelope, hard cut at `length`."""
    if t >= length:
        return 0.0
    if t < attack:
        return t / attack
    return math.exp(-(t - attack) * decay)


def render(length, fn):
    """fn(t) -> sample in [-1, 1]. Returns int16 samples."""
    n = int(length * RATE)
    out = []
    for i in range(n):
        s = max(-1.0, min(1.0, fn(i / RATE)))
        out.append(int(s * 32000))
    return out


def lowpass(samples, alpha):
    y = 0.0
    out = []
    for s in samples:
        y += alpha * (s - y)
        out.append(int(y))
    return out


def save(path, samples):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(struct.pack("<%dh" % len(samples), *samples))
    print("wrote", os.path.relpath(path, ROOT), "%.2fs" % (len(samples) / RATE))


# --- sound effects -------------------------------------------------------

def sfx_drop():
    # quick descending blip: "let go"
    return render(0.14, lambda t: 0.5 * square(t, 700 - 2500 * t) * env(t, 0.005, 25, 0.14))


def sfx_land():
    # soft thud: low sine + a click of noise
    return render(0.18, lambda t:
                  0.8 * sine(t, 110 - 200 * t) * env(t, 0.003, 22, 0.18)
                  + 0.25 * noise(t, 0) * env(t, 0.001, 120, 0.05))


def sfx_perfect():
    # two rising notes, bright
    def f(t):
        if t < 0.11:
            return 0.45 * square(t, 880) * env(t, 0.004, 14, 0.11)
        u = t - 0.11
        return 0.45 * square(u, 1318) * env(u, 0.004, 9, 0.3)
    return render(0.4, f)


def sfx_miss():
    # descending buzz, slightly gritty
    return render(0.32, lambda t: 0.4 * saw(t, 260 - 380 * t) * env(t, 0.01, 8, 0.32))


def sfx_collapse():
    # rumble: filtered noise plus a low tone falling away
    s = render(0.9, lambda t:
               0.9 * noise(t, 0) * env(t, 0.02, 4, 0.9)
               + 0.5 * sine(t, 70 - 40 * t) * env(t, 0.02, 3, 0.9))
    return lowpass(s, 0.08)


def sfx_splash():
    # bright noise burst that darkens
    s = render(0.5, lambda t: 0.9 * noise(t, 0) * env(t, 0.01, 7, 0.5))
    return lowpass(s, 0.35)


def sfx_start():
    # rising three-note arpeggio
    notes = [523.25, 659.25, 783.99]
    def f(t):
        i = min(int(t / 0.09), 2)
        u = t - i * 0.09
        return 0.4 * triangle(u, notes[i]) * env(u, 0.004, 10, 0.3)
    return render(0.4, f)


def sfx_game_over():
    # slow descending pair of notes
    def f(t):
        if t < 0.3:
            return 0.4 * square(t, 392) * env(t, 0.01, 6, 0.3)
        u = t - 0.3
        return 0.4 * square(u, 293.66) * env(u, 0.01, 4, 0.6)
    return render(0.9, f)


# --- music loop ----------------------------------------------------------

def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12)


def music_loop():
    """8 bars, 120 BPM, A minor: Am F C G, arpeggio + bass. Loops cleanly."""
    bpm = 120
    beat = 60 / bpm
    bar = 4 * beat
    chords = [  # (bass midi, arpeggio midi notes)
        (45, [57, 60, 64, 67]),  # Am7
        (41, [53, 57, 60, 64]),  # Fmaj7
        (48, [60, 64, 67, 71]),  # Cmaj7
        (43, [55, 59, 62, 67]),  # G
    ]
    length = bar * 8
    eighth = beat / 2

    def f(t):
        bar_i = int(t / bar) % 8
        bass_n, arp = chords[bar_i % 4]
        tb = t % bar
        # bass: root on beats 1 and 3, fifth on 2 and 4
        beat_i = int(tb / beat)
        bass_note = bass_n if beat_i % 2 == 0 else bass_n + 7
        u = tb % beat
        bass = 0.22 * triangle(t, midi(bass_note)) * env(u, 0.01, 3, beat)
        # arpeggio: eighth notes, up-down pattern; busier in the second half
        step = int(tb / eighth)
        pattern = [0, 1, 2, 3, 2, 1, 0, 2] if bar_i < 4 else [0, 2, 1, 3, 0, 3, 2, 1]
        n = arp[pattern[step % 8]] + (12 if bar_i >= 4 else 0)
        v = tb % eighth
        lead = 0.13 * square(t, midi(n)) * env(v, 0.005, 9, eighth)
        # soft pad: chord root an octave up, very quiet
        pad = 0.05 * sine(t, midi(bass_n + 12))
        return bass + lead + pad

    return render(length, f)


if __name__ == "__main__":
    random.seed(7)
    for name, fn in [
        ("drop", sfx_drop), ("land", sfx_land), ("perfect", sfx_perfect),
        ("miss", sfx_miss), ("collapse", sfx_collapse), ("splash", sfx_splash),
        ("start", sfx_start), ("game_over", sfx_game_over),
    ]:
        save(os.path.join(ROOT, "sfx", name + ".wav"), fn())
    save(os.path.join(ROOT, "music", "loop.wav"), music_loop())
