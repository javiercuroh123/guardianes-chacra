"""Genera el sprite de ejemplo del gorgojo: assets/images/pests/gorgojo.png.

Es una tira de 4 cuadros de 128 x 128 px (512 x 128 en total), vista desde
arriba y mirando a la derecha, con las patas en movimiento. Sirve para probar
la carga de sprites y la animación (ver docs/ASSETS.md); el arte definitivo
lo reemplaza con el mismo formato.

Las demás plagas y los guardianes siguen dibujándose con formas hasta tener
su imagen: no hace falta que todas la tengan.

Solo usa la biblioteca estándar de Python. Uso (desde la raíz del proyecto):

    python tool/generate_placeholder_sprites.py
"""

import math
import struct
import zlib
from pathlib import Path

FRAME = 128
FRAMES = 4
OUT = Path(__file__).resolve().parent.parent / "assets" / "images" / "pests" / "gorgojo.png"

OUTLINE = (27, 18, 16, 255)
SHELL = (78, 52, 46, 255)
SHELL_LIGHT = (121, 85, 72, 255)
THORAX = (62, 39, 35, 255)
EYE = (240, 220, 180, 255)


def in_ellipse(x, y, cx, cy, rx, ry):
    return ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1


def near_segment(x, y, ax, ay, bx, by, width):
    dx, dy = bx - ax, by - ay
    t = max(0.0, min(1.0, ((x - ax) * dx + (y - ay) * dy) / (dx * dx + dy * dy)))
    px, py = ax + t * dx, ay + t * dy
    return math.hypot(x - px, y - py) <= width / 2


def beetle(frame):
    """Devuelve una función (x, y) -> color RGBA o None para el cuadro dado."""
    bob = (0, -1, 0, 1)[frame]
    # Paso en trípode: las patas 1 y 3 de un lado van con la 2 del otro.
    swing = (7, 0, -7, 0)[frame]
    legs = []
    for index, lx in enumerate((48, 64, 80)):
        phase = swing if index % 2 == 0 else -swing
        legs.append((lx, 64 + bob - 16, lx + phase, 64 + bob - 36))
        legs.append((lx, 64 + bob + 16, lx - phase, 64 + bob + 36))
    antennae = [(104, 60 + bob, 120, 46 + bob), (104, 68 + bob, 120, 82 + bob)]

    def color(x, y):
        cy = 64 + bob
        # El cuerpo con su borde (se dibuja del frente hacia atrás).
        if in_ellipse(x, y, 106, cy, 9, 8):
            if in_ellipse(x, y, 109, cy - 4, 2, 2) or in_ellipse(x, y, 109, cy + 4, 2, 2):
                return EYE
            return THORAX if in_ellipse(x, y, 106, cy, 7, 6) else OUTLINE
        if in_ellipse(x, y, 88, cy, 13, 16):
            return THORAX if in_ellipse(x, y, 88, cy, 11, 14) else OUTLINE
        if in_ellipse(x, y, 56, cy, 32, 24):
            if not in_ellipse(x, y, 56, cy, 30, 22):
                return OUTLINE
            if abs(y - cy) <= 1 and 28 < x < 84:
                return OUTLINE  # La línea entre las dos alas.
            return SHELL_LIGHT if in_ellipse(x, y, 50, cy - 9, 14, 6) else SHELL
        for leg in legs + antennae:
            if near_segment(x, y, *leg, 3.5):
                return OUTLINE
        return None

    return color


def render():
    width, height = FRAME * FRAMES, FRAME
    painters = [beetle(frame) for frame in range(FRAMES)]
    raw = bytearray()
    for y in range(height):
        raw.append(0)  # Filtro "None" en cada fila.
        for x in range(width):
            frame, fx = divmod(x, FRAME)
            # 4 muestras por píxel para suavizar los bordes.
            total = [0.0, 0.0, 0.0, 0.0]
            for sx, sy in ((0.25, 0.25), (0.75, 0.25), (0.25, 0.75), (0.75, 0.75)):
                rgba = painters[frame](fx + sx, y + sy)
                if rgba:
                    a = rgba[3] / 255
                    total[0] += rgba[0] * a
                    total[1] += rgba[1] * a
                    total[2] += rgba[2] * a
                    total[3] += a
            alpha = total[3] / 4
            if alpha == 0:
                raw.extend((0, 0, 0, 0))
            else:
                raw.extend((round(total[0] / total[3]), round(total[1] / total[3]),
                            round(total[2] / total[3]), round(alpha * 255)))

    def chunk(kind, data):
        body = kind + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body))

    header = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)  # RGBA
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", header)
            + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b""))


def main():
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_bytes(render())
    print(f"{OUT.relative_to(OUT.parents[3])}: {FRAME * FRAMES} x {FRAME} px, "
          f"{FRAMES} cuadros, {OUT.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()
