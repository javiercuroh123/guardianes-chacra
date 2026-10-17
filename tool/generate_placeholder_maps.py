"""Genera los 3 mapas de prueba en assets/tiles/ (formato TMX de Tiled).

Cada mapa tiene 26 x 12 casillas de 64 px y las capas que espera el juego:
"terreno" (casillas), "caminos" (polilíneas con nombre), "espacios"
(puntos) y "collca" (un punto). Ver docs/TILED.md.

Es solo para crear los mapas iniciales: una vez que los editas en Tiled, ese
archivo es el original. Por eso no sobrescribe un mapa que ya existe salvo
con --force.

    python tool/generate_placeholder_maps.py [--force]
"""

import argparse
import math
from pathlib import Path

WIDTH, HEIGHT, TILE = 26, 12, 64
OUT_DIR = Path(__file__).resolve().parent.parent / "assets" / "tiles"

# gids de placeholder.tsx (ver generate_placeholder_tileset.py).
GRASS, DIRT, WATER, TERRACE, ROCK, PAD, COLLCA, FLOWERS = range(1, 9)

# Un espacio debe quedar a esta distancia (en casillas) de algún camino.
MAX_SLOT_DISTANCE = 3.2

# Coordenadas en casillas; x.5 es el centro de una casilla.
MAPS = {
    "chacra_del_valle": {
        "paths": {
            "camino": [
                (0, 2.5), (6.5, 2.5), (6.5, 8.5), (13.5, 8.5),
                (13.5, 3.5), (20.5, 3.5), (20.5, 7.5), (24.5, 7.5),
            ],
        },
        "collca": (24.5, 7.5),
        "slots": [
            (4.5, 4.5), (8.5, 1.5), (8.5, 6.5), (11.5, 5.5), (10.5, 10.5),
            (15.5, 5.5), (17.5, 1.5), (18.5, 9.5), (22.5, 5.5), (23.5, 9.5),
        ],
        "water": [],
        "terraces": False,
    },
    "andenes": {
        "paths": {
            "norte": [(0, 1.5), (9.5, 1.5), (9.5, 5.5), (24.5, 5.5)],
            "sur": [
                (0, 10.5), (5.5, 10.5), (5.5, 7.5), (14.5, 7.5),
                (14.5, 5.5), (24.5, 5.5),
            ],
        },
        "collca": (24.5, 5.5),
        "slots": [
            (3.5, 3.5), (7.5, 3.5), (11.5, 3.5), (3.5, 8.5), (8.5, 9.5),
            (12.5, 9.5), (12.5, 6.5), (16.5, 6.5), (17.5, 3.5), (17.5, 7.5),
            (21.5, 3.5), (21.5, 7.5),
        ],
        "water": [],
        "terraces": True,
    },
    "orilla_del_lago": {
        "paths": {
            "orilla": [
                (0, 9.5), (5.5, 9.5), (5.5, 1.5), (20.5, 1.5),
                (20.5, 9.5), (24.5, 9.5),
            ],
        },
        "collca": (24.5, 9.5),
        "slots": [
            (2.5, 7.5), (3.5, 3.5), (7.5, 3.5), (7.5, 7.5), (9.5, 0.5),
            (12.5, 3.5), (15.5, 0.5), (17.5, 3.5), (18.5, 6.5),
            (22.5, 7.5), (18.5, 10.5), (22.5, 11.5),
        ],
        # Rectángulos de agua: (x0, y0, x1, y1) en casillas, inclusivos.
        "water": [(8, 4, 17, 8)],
        "terraces": False,
    },
}


def noise(x, y):
    value = ((x * 73856093) ^ (y * 19349663)) * 2654435761 & 0xFFFFFFFF
    return value / 0x100000000


def path_cells(points):
    cells = set()
    for (x0, y0), (x1, y1) in zip(points, points[1:]):
        steps = max(1, int(math.dist((x0, y0), (x1, y1)) * 20))
        for step in range(steps + 1):
            t = step / steps
            x, y = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
            cell = (min(WIDTH - 1, int(x)), min(HEIGHT - 1, int(y)))
            cells.add(cell)
    return cells


def distance_to_segment(point, start, end):
    (px, py), (ax, ay), (bx, by) = point, start, end
    dx, dy = bx - ax, by - ay
    length2 = dx * dx + dy * dy
    t = 0 if length2 == 0 else max(0, min(1, ((px - ax) * dx + (py - ay) * dy) / length2))
    return math.dist(point, (ax + dx * t, ay + dy * t))


def build_grid(name, spec):
    grid = [
        [FLOWERS if noise(x, y) < 0.06 else GRASS for x in range(WIDTH)]
        for y in range(HEIGHT)
    ]
    if spec["terraces"]:
        for y in range(0, HEIGHT, 3):
            grid[y] = [TERRACE] * WIDTH
    water = set()
    for x0, y0, x1, y1 in spec["water"]:
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                grid[y][x] = WATER
                water.add((x, y))

    road = set()
    for points in spec["paths"].values():
        road |= path_cells(points)
        assert points[-1] == spec["collca"], f"{name}: un camino no llega a la collca"
    for x, y in road:
        grid[y][x] = DIRT

    for slot in spec["slots"]:
        cell = (int(slot[0]), int(slot[1]))
        assert cell not in road, f"{name}: el espacio {slot} está sobre el camino"
        assert cell not in water, f"{name}: el espacio {slot} está en el agua"
        nearest = min(
            distance_to_segment(slot, a, b)
            for points in spec["paths"].values()
            for a, b in zip(points, points[1:])
        )
        assert nearest <= MAX_SLOT_DISTANCE, f"{name}: el espacio {slot} está lejos del camino"
        grid[cell[1]][cell[0]] = PAD

    collca_x, collca_y = spec["collca"]
    grid[int(collca_y)][int(collca_x)] = COLLCA
    return grid


def px(value):
    pixels = value * TILE
    return str(int(pixels)) if pixels == int(pixels) else str(pixels)


def tmx(name, spec):
    grid = build_grid(name, spec)
    rows = [",".join(str(gid) for gid in row) for row in grid]
    data = ",\n".join(rows)

    next_id = 1
    path_objects = []
    for path_id, points in spec["paths"].items():
        x0, y0 = points[0]
        relative = " ".join(f"{px(x - x0)},{px(y - y0)}" for x, y in points)
        path_objects.append(
            f'  <object id="{next_id}" name="{path_id}" x="{px(x0)}" y="{px(y0)}">\n'
            f'   <polyline points="{relative}"/>\n'
            "  </object>"
        )
        next_id += 1

    slot_objects = []
    for index, (x, y) in enumerate(spec["slots"], start=1):
        slot_objects.append(
            f'  <object id="{next_id}" name="e{index}" x="{px(x)}" y="{px(y)}">\n'
            "   <point/>\n"
            "  </object>"
        )
        next_id += 1

    collca_x, collca_y = spec["collca"]
    collca_object = (
        f'  <object id="{next_id}" name="collca" x="{px(collca_x)}" y="{px(collca_y)}">\n'
        "   <point/>\n"
        "  </object>"
    )
    next_id += 1

    return (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        f'<map version="1.10" tiledversion="1.12.2" orientation="orthogonal" '
        f'renderorder="right-down" width="{WIDTH}" height="{HEIGHT}" '
        f'tilewidth="{TILE}" tileheight="{TILE}" infinite="0" '
        f'nextlayerid="5" nextobjectid="{next_id}">\n'
        ' <tileset firstgid="1" source="placeholder.tsx"/>\n'
        f' <layer id="1" name="terreno" width="{WIDTH}" height="{HEIGHT}">\n'
        f'  <data encoding="csv">\n{data}\n</data>\n'
        " </layer>\n"
        ' <objectgroup id="2" name="caminos">\n'
        + "\n".join(path_objects)
        + "\n </objectgroup>\n"
        ' <objectgroup id="3" name="espacios">\n'
        + "\n".join(slot_objects)
        + "\n </objectgroup>\n"
        ' <objectgroup id="4" name="collca">\n'
        + collca_object
        + "\n </objectgroup>\n"
        "</map>\n"
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--force", action="store_true", help="sobrescribir mapas existentes")
    args = parser.parse_args()

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for name, spec in MAPS.items():
        target = OUT_DIR / f"{name}.tmx"
        if target.exists() and not args.force:
            print(f"Omitido {target.name}: ya existe (usa --force para reemplazarlo)")
            continue
        target.write_text(tmx(name, spec), encoding="utf-8", newline="\n")
        print(f"Escrito {target.name}")


if __name__ == "__main__":
    main()
