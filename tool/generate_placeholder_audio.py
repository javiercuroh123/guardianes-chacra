"""Genera los sonidos de prueba: assets/audio/sfx/*.wav y assets/audio/music/*.wav.

Son sonidos sintetizados (sin grabaciones ni muestras de terceros), así que no
tienen licencia que revisar. Sirven para probar el sistema de audio hasta
tener los definitivos (ver docs/ASSETS.md); se reemplazan cambiando los
archivos o las rutas de assets/content/audio.json y de cada nivel.

Las melodías usan la escala pentatónica menor de La (La, Do, Re, Mi, Sol),
común en la música andina.

Solo usa la biblioteca estándar de Python. Uso (desde la raíz del proyecto):

    python tool/generate_placeholder_audio.py
"""

import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
ROOT = Path(__file__).resolve().parent.parent / "assets" / "audio"

# Pentatónica menor de La, en Hz.
A2, C3, D3, E3, G3 = 110.0, 130.81, 146.83, 164.81, 196.0
A3, C4, D4, E4, G4 = 220.0, 261.63, 293.66, 329.63, 392.0
A4, C5, D5, E5, G5, A5 = 440.0, 523.25, 587.33, 659.25, 783.99, 880.0
E6, B6 = 1318.51, 1975.53


def silence(seconds):
    return [0.0] * int(seconds * RATE)


def mix(base, sound, at):
    """Suma [sound] a [base] desde el segundo [at] (alargando si hace falta)."""
    start = int(at * RATE)
    end = start + len(sound)
    if end > len(base):
        base.extend([0.0] * (end - len(base)))
    for i, sample in enumerate(sound):
        base[start + i] += sample
    return base


def tone(freq_from, seconds, freq_to=None, shape="sine", decay=6.0,
         attack=0.005, amp=0.6, vibrato=0.0):
    """Un tono con ataque corto y caída exponencial; la frecuencia puede
    deslizarse de [freq_from] a [freq_to]."""
    freq_to = freq_from if freq_to is None else freq_to
    count = int(seconds * RATE)
    out = []
    phase = 0.0
    for i in range(count):
        t = i / RATE
        progress = i / max(count - 1, 1)
        freq = freq_from + (freq_to - freq_from) * progress
        if vibrato:
            freq *= 1 + 0.01 * math.sin(2 * math.pi * vibrato * t)
        phase += freq / RATE
        cycle = phase % 1.0
        if shape == "square":
            value = 1.0 if cycle < 0.5 else -1.0
        elif shape == "triangle":
            value = 4 * abs(cycle - 0.5) - 1
        elif shape == "horn":
            # Varios armónicos: un sonido de caracola (pututu).
            value = sum(math.sin(2 * math.pi * cycle * h) / h for h in (1, 2, 3, 4))
            value *= 0.6
        else:
            value = math.sin(2 * math.pi * cycle)
        envelope = min(t / attack, 1.0) * math.exp(-decay * t)
        out.append(value * envelope * amp)
    return out


def noise(seconds, decay=30.0, amp=0.5, seed=1, smooth=0.0):
    """Ruido con caída rápida; [smooth] (0–1) lo hace más grave."""
    rng = random.Random(seed)
    out = []
    last = 0.0
    for i in range(int(seconds * RATE)):
        t = i / RATE
        value = rng.uniform(-1, 1)
        last = last * smooth + value * (1 - smooth)
        out.append(last * math.exp(-decay * t) * amp)
    return out


def pluck(freq, seconds=0.5, amp=0.45):
    """Una cuerda pulsada (como un charango, muy simplificado)."""
    return mix(tone(freq, seconds, shape="triangle", decay=7, amp=amp),
               tone(freq * 2, seconds, decay=12, amp=amp * 0.3), 0)


def drum(seconds=0.35, amp=0.7):
    """Un bombo: tono grave que cae, con un golpe de ruido."""
    return mix(tone(110, seconds, freq_to=45, decay=12, amp=amp),
               noise(0.05, decay=60, amp=amp * 0.4, smooth=0.6), 0)


# --- Efectos

def shot():
    return mix(noise(0.12, decay=35, amp=0.45, smooth=0.3),
               tone(700, 0.1, freq_to=320, decay=30, amp=0.3), 0)


def impact():
    return mix(tone(150, 0.14, freq_to=70, decay=28, amp=0.7),
               noise(0.04, decay=80, amp=0.35, smooth=0.5), 0)


def pest_defeated():
    return mix(tone(660, 0.08, shape="square", decay=20, amp=0.25),
               tone(990, 0.12, shape="square", decay=18, amp=0.25), 0.07)


def collca_damaged():
    return tone(440, 0.4, freq_to=220, shape="triangle", decay=4, amp=0.55,
                vibrato=9)


def victory():
    out = silence(0)
    for index, freq in enumerate((A4, C5, D5, E5, G5)):
        mix(out, pluck(freq, 0.4), index * 0.13)
    return mix(out, pluck(A5, 1.0, amp=0.5), 5 * 0.13)


def defeat():
    out = silence(0)
    for index, freq in enumerate((E4, D4, C4)):
        mix(out, tone(freq, 0.5, shape="triangle", decay=3, amp=0.5),
            index * 0.32)
    return mix(out, tone(A3, 1.0, shape="triangle", decay=2.5, amp=0.5),
               3 * 0.32)


def boss():
    out = mix(drum(), drum(), 0.3)
    return mix(out, tone(A2, 1.3, freq_to=D3, shape="horn", decay=1.2,
                         attack=0.15, amp=0.5), 0.1)


def ui_tap():
    """El toque de un botón de la interfaz: un clic corto y suave."""
    return mix(tone(1320, 0.05, freq_to=990, decay=55, amp=0.3),
               noise(0.015, decay=150, amp=0.15, seed=3, smooth=0.6), 0)


def ui_deny():
    """"No se puede" (no alcanza el maíz): dos notas graves y cortas."""
    out = tone(200, 0.09, shape="square", decay=14, amp=0.2)
    return mix(out, tone(150, 0.12, shape="square", decay=12, amp=0.2), 0.1)


def star():
    """Una estrella de la victoria: dos notas agudas que suben, con brillo."""
    out = pluck(E6, 0.25, amp=0.35)
    out = mix(out, pluck(B6, 0.45, amp=0.4), 0.07)
    return mix(out, noise(0.12, decay=40, amp=0.06, seed=5, smooth=0.3), 0.07)


# --- Música (bucles: la última nota termina antes del final)

def melody_loop(beat, notes, bass, drums_every=None):
    """[notes]: (tiempo en pulsos, frecuencia); [bass]: notas del bajo, una
    por compás de 4 pulsos."""
    total = 16 * beat
    out = silence(total)
    for at, freq in notes:
        mix(out, pluck(freq, beat * 1.6), at * beat)
    for bar, freq in enumerate(bass):
        mix(out, tone(freq, beat * 3.5, shape="triangle", decay=1.5,
                      attack=0.02, amp=0.3), bar * 4 * beat)
    if drums_every:
        for step in range(0, 16, drums_every):
            mix(out, drum(amp=0.45), step * beat)
    return out[: int(total * RATE)]


def music_menu():
    notes = [(0, A4), (1, C5), (2, E5), (3, D5), (4, C5), (5, A4), (6, G4),
             (7, A4), (8, E5), (9, D5), (10, C5), (11, D5), (12, A4),
             (14, G4)]
    return melody_loop(0.8, notes, (A2, G3 / 2, C3, A2))


def music_battle():
    notes = [(i * 0.5, freq) for i, freq in enumerate(
        (A4, A4, C5, D5, E5, D5, C5, A4, G4, A4, C5, A4, E5, G5, E5, D5,
         C5, C5, D5, E5, A5, G5, E5, D5, C5, A4, G4, A4, A4, C5, A4, A4))]
    return melody_loop(0.5, notes[:30], (A2, C3, G3 / 2, A2), drums_every=1)


def write(path, samples):
    peak = max(1e-9, max(abs(s) for s in samples))
    scale = 0.85 / peak if peak > 0.85 else 1.0
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, s * scale)) * 32767))
            for s in samples))
    print(f"{path.relative_to(ROOT.parent.parent)}: "
          f"{len(samples) / RATE:.2f} s, {path.stat().st_size // 1024} KB")


def main():
    for name, make in (("shot", shot), ("impact", impact),
                       ("pest_defeated", pest_defeated),
                       ("collca_damaged", collca_damaged),
                       ("victory", victory), ("defeat", defeat),
                       ("boss", boss), ("ui_tap", ui_tap),
                       ("ui_deny", ui_deny), ("star", star)):
        write(ROOT / "sfx" / f"{name}.wav", make())
    write(ROOT / "music" / "menu.wav", music_menu())
    write(ROOT / "music" / "batalla.wav", music_battle())


if __name__ == "__main__":
    main()
