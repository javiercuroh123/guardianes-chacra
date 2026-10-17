"""Genera el tileset de prueba: assets/tiles/placeholder.png y placeholder.tsx.

Son 8 casillas de 64 px (4 columnas x 2 filas), con colores planos y un
patrón sencillo para distinguirlas. Las reemplaza el arte real en la Fase 8.

    gid 1 pasto     gid 2 tierra (camino)   gid 3 agua      gid 4 andén
    gid 5 roca      gid 6 espacio           gid 7 collca    gid 8 flores

Solo usa la biblioteca estándar de Python. Uso (desde la raíz del proyecto):

    python tool/generate_placeholder_tileset.py
"""

import struct
import zlib
from pathlib import Path

TILE = 64
COLUMNS = 4
ROWS = 2
OUT_DIR = Path(__file__).resolve().parent.parent / "assets" / "tiles"

GRASS = (106, 176, 76)
GRASS_DARK = (86, 150, 60)
DIRT = (196, 160, 108)
DIRT_DARK = (160, 128, 84)
WATER = (74, 144, 194)
WATER_LIGHT = (130, 186, 226)
TERRACE = (150, 118, 84)
TERRACE_LINE = (110, 84, 58)
ROCK = (140, 140, 140)
ROCK_DARK = (104, 104, 104)
PAD = (232, 204, 128)
PAD_BORDER = (150, 110, 50)
COLLCA = (168, 96, 56)
COLLCA_DOOR = (90, 50, 28)
YELLOW = (250, 220, 70)
WHITE = (250, 250, 240)


def noise(x, y, seed):
    """Valor pseudoaleatorio estable en [0, 1) para la posición (x, y)."""
    value = (x * 73856093) ^ (y * 19349663) ^ (seed * 83492791)
    value = (value * 2654435761) & 0xFFFFFFFF
    return value / 0x100000000


def grass(x, y):
    return GRASS_DARK if noise(x, y, 1) < 0.08 else GRASS


def dirt(x, y):
    return DIRT_DARK if noise(x, y, 2) < 0.06 else DIRT


def water(x, y):
    return WATER_LIGHT if (y + (x // 8) % 3) % 16 == 0 else WATER


def terrace(x, y):
    return TERRACE_LINE if y % 16 in (0, 1) or x % 32 == 0 else TERRACE


def rock(x, y):
    return ROCK_DARK if noise(x, y, 3) < 0.12 else ROCK


def pad(x, y):
    margin = 6
    inside = margin <= x < TILE - margin and margin <= y < TILE - margin
    if not inside:
        return grass(x, y)
    border = min(x - margin, y - margin, TILE - margin - 1 - x, TILE - margin - 1 - y)
    return PAD_BORDER if border < 3 else PAD


def collca(x, y):
    door = 24 <= x < 40 and y >= 36
    return COLLCA_DOOR if door else COLLCA


def flowers(x, y):
    cell_x, cell_y = x // 8, y // 8
    if noise(cell_x, cell_y, 4) < 0.18 and x % 8 in (3, 4) and y % 8 in (3, 4):
        return YELLOW if noise(cell_x, cell_y, 5) < 0.5 else WHITE
    return grass(x, y)


TILES = [grass, dirt, water, terrace, rock, pad, collca, flowers]


def png_bytes(width, height, pixel):
    raw = bytearray()
    for y in range(height):
        raw.append(0)  # Filtro "None" en cada fila.
        for x in range(width):
            raw.extend(pixel(x, y))

    def chunk(kind, data):
        body = kind + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body))

    header = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    return (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", header)
        + chunk(b"IDAT", zlib.compress(bytes(raw), 9))
        + chunk(b"IEND", b"")
    )


def tileset_pixel(x, y):
    index = (y // TILE) * COLUMNS + (x // TILE)
    return TILES[index](x % TILE, y % TILE)


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    width, height = TILE * COLUMNS, TILE * ROWS
    (OUT_DIR / "placeholder.png").write_bytes(png_bytes(width, height, tileset_pixel))
    (OUT_DIR / "placeholder.tsx").write_text(
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        f'<tileset version="1.10" tiledversion="1.12.2" name="placeholder" '
        f'tilewidth="{TILE}" tileheight="{TILE}" tilecount="{COLUMNS * ROWS}" '
        f'columns="{COLUMNS}">\n'
        f' <image source="placeholder.png" width="{width}" height="{height}"/>\n'
        "</tileset>\n",
        encoding="utf-8",
    )
    print(f"Tileset escrito en {OUT_DIR}")


if __name__ == "__main__":
    main()
