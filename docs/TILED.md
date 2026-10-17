# Mapas con Tiled

Los niveles se dibujan en [Tiled](https://www.mapeditor.org/), un editor de mapas gratuito. Los mapas viven en `assets/tiles/` junto a su tileset (`placeholder.tsx` + `placeholder.png`), que es donde los busca `flame_tiled`.

## 1. Instalar Tiled en Windows

Versión probada: **Tiled 1.12.2**.

Opción A, con winget (en PowerShell):

```powershell
winget install --id Tiled.Tiled
```

Opción B: descarga `Tiled-1.12.2_Windows-10+_x86_64.msi` desde la página de *releases* de Tiled en GitHub (`github.com/mapeditor/tiled/releases`) o desde mapeditor.org, y ejecútalo.

## 2. Lo que debe tener todo mapa

| Capa | Tipo | Qué contiene |
|---|---|---|
| `terreno` | Capa de patrones (tiles) | Lo que se dibuja: pasto, camino, agua… Solo es decorado; el juego no lee reglas de aquí. |
| `caminos` | Capa de objetos | Una **polilínea** por camino. Su **nombre** es su id (el que usan las oleadas en `"path"`). El primer punto es la entrada y el último debe quedar a menos de 0,75 casillas de la collca. |
| `espacios` | Capa de objetos | Un **punto** por espacio de construcción. El nombre es opcional (si falta, el id es `espacio_<id del objeto>`); los mapas de prueba usan `e1`, `e2`… |
| `collca` | Capa de objetos | **Exactamente un punto**: la collca. |

Reglas generales:

- Casillas **cuadradas** (los mapas de prueba usan 64 px). El juego trabaja en casillas: divide los píxeles entre el tamaño de la casilla.
- Mapas de prueba: 26 × 12 casillas, una proporción parecida a la de un teléfono en horizontal.
- Los nombres de capas y objetos distinguen mayúsculas.

## 3. Ejercicio: editar Andenes

1. Abre Tiled → **File → Open** → `assets/tiles/andenes.tmx`.
2. En el panel **Layers**, selecciona `espacios`.
3. **Mover un espacio**: herramienta **Select Objects** (`S`), arrastra el punto `e7` una casilla a la derecha. Para que quede centrado, activa **View → Snapping → Snap to Fine Grid** o ajusta `X`/`Y` en el panel **Properties** (múltiplos de 64 + 32 dejan el punto en el centro de una casilla).
4. **Agregar un espacio**: herramienta **Insert Point** (`I`), haz clic en una casilla de pasto cerca del camino y, en **Properties**, ponle de nombre `e13`.
5. **Doblar un camino**: selecciona la capa `caminos`, herramienta **Edit Polygons** (`E`) y arrastra un punto intermedio de `sur`. (Con Select Objects, doble clic sobre la polilínea también entra a editarla).
6. **Pinta el terreno** para que el dibujo coincida: capa `terreno`, herramienta **Stamp Brush** (`B`) y el tile de tierra del tileset.
7. Guarda (**Ctrl+S**) y comprueba que el mapa sigue siendo válido:

   ```powershell
   flutter test test/features/content
   ```

   Si algo quedó mal, el test lo dice con el archivo y el motivo, por ejemplo:

   ```
   tiles/andenes.tmx: el camino "sur" termina en (20.5, 5.5), lejos de la collca (24.5, 5.5)
   ```

## 4. Crear un camino nuevo

1. Capa `caminos` → herramienta **Insert Polygon** (`P`).
2. Haz clic en cada punto del camino, desde la entrada hasta la collca.
3. Para terminarlo como **polilínea** (y no como polígono cerrado), haz **clic derecho** o pulsa **Enter**. `Escape` cancela.
4. En **Properties**, dale un **nombre** (por ejemplo `oeste`) y úsalo en las oleadas del nivel: `"path": "oeste"`.

## 5. Crear un nivel nuevo

1. **File → New → New Map**: orientación *Orthogonal*, formato de capa CSV, casillas de 64 × 64 px, tamaño fijo (por ejemplo 26 × 12). Guárdalo en `assets/tiles/<id>.tmx`.
2. **Map → Add External Tileset…** → `assets/tiles/placeholder.tsx`.
3. Renombra la capa de patrones a `terreno` y crea las tres capas de objetos (**Layer → New → Object Layer**): `caminos`, `espacios` y `collca`.
4. Dibuja el terreno, los caminos, los espacios y la collca.
5. Crea `assets/content/levels/<id>.json` con `"map": "<id>.tmx"` y sus oleadas (ver `docs/CONTENIDO.md`), agrega el id a `levels` en `assets/content/index.json` y su nombre (`level.<id>.name`) en `assets/content/i18n/es.json` y `en.json`.
6. Corre `flutter test test/features/content`.

## Notas

- `tool/generate_placeholder_maps.py` creó los tres mapas de prueba. Desde que editas un mapa en Tiled, **ese archivo es el original**: el script no lo sobrescribe salvo con `--force`.
- `tool/generate_placeholder_tileset.py` crea el tileset de prueba (8 casillas: pasto, tierra, agua, andén, roca, espacio, collca y flores). El arte real llega en la Fase 8.
