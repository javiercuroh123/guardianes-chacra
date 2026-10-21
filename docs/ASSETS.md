# Arte y sonido: qué hace falta y de dónde sacarlo

El juego funciona sin ningún archivo de arte o sonido: lo que falta se dibuja con formas o queda en silencio. Por ahora hay **placeholders generados por scripts** (sin licencias de terceros):

- `tool/generate_placeholder_sprites.py` → `assets/images/pests/gorgojo.png` (el único sprite, para probar la animación).
- `tool/generate_placeholder_audio.py` → `assets/audio/sfx/*.wav` y `assets/audio/music/*.wav`.
- `tool/generate_placeholder_tileset.py` → el tileset de los mapas (Fase 4).

Para reemplazarlos basta con poner el archivo nuevo y apuntar a él desde los datos (ver abajo). El test `real_content_test.dart` avisa si un archivo nombrado en los datos no existe, si su carpeta no está en `pubspec.yaml` o si un sprite no se divide en sus cuadros.

## Cómo se conectan

**Sprites** (`"sprite"` en el JSON de una plaga, de un guardián o de un nivel o rama de un guardián):

```json
"sprite": { "image": "pests/gorgojo.png", "frames": 4, "fps": 8 }
```

- `image`: ruta dentro de `assets/images/` (`.png`, en minúsculas).
- Una **tira horizontal** de `frames` cuadros cuadrados del mismo tamaño (`ancho = frames × alto`). `frames` por defecto 1 (imagen fija); `fps` por defecto 8.
- **Vista desde arriba, mirando a la derecha.** Las plagas se espejan solas cuando caminan hacia la izquierda; no rotan.
- Un guardián puede tener un `"sprite"` general y otro en cada nivel o rama (se usa el más específico). La "honda" que apunta al objetivo se sigue dibujando encima.
- Cada carpeta nueva dentro de `assets/images/` (por ejemplo `assets/images/guardians/`) se agrega a `pubspec.yaml`.

**Audio** (`assets/content/audio.json` y `"music"` en cada nivel): rutas dentro de `assets/audio/` con extensión `.wav`, `.ogg`, `.mp3` o `.m4a`. Los efectos son `shot`, `impact`, `pestDefeated`, `collcaDamaged`, `victory`, `defeat`, `boss`, `uiTap`, `uiDeny` y `star`.

## Lista de lo que hace falta

### Sprites

En el juego, una casilla mide 64 px del mundo. En un teléfono como el Redmi Note 14 Pro una casilla ocupa unos 88 píxeles físicos, así que el arte se pide al **doble (128 px por casilla)** para que se vea nítido. El cuadro de una plaga es una casilla y el dibujo debería ocupar más o menos el 70 % (deja aire para las patas y las alas).

| Qué | Cuántos | Tamaño por cuadro | Cuadros | Notas |
|---|---|---|---|---|
| Plagas que caminan: gorgojo, langosta, escarabajo, espíritu de la helada, granizo, granizo chico | 6 | 128 × 128 | 4–6 (caminar) | El gorgojo ya tiene un placeholder con este formato. |
| Plaga voladora: polilla | 1 | 128 × 128 | 2–4 (aleteo) | |
| Jefe: Rey Gorgojo | 1 | 192 × 192 | 4–6 | Se dibuja a 1,5 casillas. |
| Guardianes: hondero, llama, tullpa, cóndor, pututu | 5 | 128 × 128 | 1 (o 2–4 en reposo) | Ideal: una imagen por nivel (3) y por rama (2) para que se note la mejora: hasta 25 imágenes. Con una sola por guardián también funciona. |
| Tileset de los mapas | 1 | 64 × 64 por casilla | — | Las 8 casillas del placeholder (pasto, tierra, agua, andén, roca, espacio, collca, flores). Para hacerlo a 128 px hay que cambiar el tamaño de casilla de los `.tmx` en Tiled. |
| Ícono de la app | 1 | 512 × 512 | — | Para la Fase 11 (Google Play). |

Formato: **PNG con transparencia (RGBA)**, sin bordes alrededor de cada cuadro.

### Sonido

| Qué | Archivo actual | Duración | Notas |
|---|---|---|---|
| Música de los menús | `music/menu.wav` | 1–2 min, en bucle | Tranquila; instrumentos andinos (quena, charango, zampoña) encajan con el tema. |
| Música de cada nivel (3) | `music/batalla.wav` (los tres usan la misma) | 1–2 min, en bucle | Más rítmica. Cada nivel puede tener la suya con `"music"`. |
| `shot` (disparo) | `sfx/shot.wav` | < 0,2 s | Suena muy seguido: corto y suave. |
| `impact` (impacto) | `sfx/impact.wav` | < 0,2 s | |
| `pestDefeated` (plaga derrotada) | `sfx/pest_defeated.wav` | < 0,3 s | |
| `collcaDamaged` (la collca pierde papas) | `sfx/collca_damaged.wav` | < 0,5 s | Debe distinguirse: es una alerta. |
| `boss` (aparece el jefe) | `sfx/boss.wav` | 1–2 s | Un pututu (caracola) sería ideal. |
| `uiTap` (tocar un botón) | `sfx/ui_tap.wav` | < 0,1 s | Un clic suave de madera o semilla; suena muchísimo. |
| `uiDeny` (no se puede, no alcanza el maíz) | `sfx/ui_deny.wav` | < 0,3 s | Claro pero sin regañar. |
| `star` (cada estrella de la victoria) | `sfx/star.wav` | < 0,6 s | Suena hasta tres veces seguidas: brillante y corto. |
| `victory` / `defeat` | `sfx/victory.wav`, `sfx/defeat.wav` | 1,5–3 s | |

Formatos:

- **Música: OGG Vorbis** (96–128 kbps). Funciona en Android y en la web y, a diferencia del MP3, hace bucles sin silencio en la unión. iOS no reproduce OGG: si algún día se publica ahí, hará falta AAC (`.m4a`).
- **Efectos: OGG o WAV** cortos, mono, 44,1 o 22,05 kHz, normalizados sin saturar.

### Interfaz (Rive)

La interfaz animada vive en `assets/rive/guardianes_ui.riv` (ver [UI_RIVE.md](UI_RIVE.md)). Lo que lleva adentro:

| Qué | Origen | Licencia | Notas |
|---|---|---|---|
| Fuente Lilita One (títulos) | [google/fonts](https://github.com/google/fonts/tree/main/ofl/lilitaone), Juan Montoreano | SIL OFL 1.1 (con nombre reservado "Lilita"): uso comercial permitido, se puede incrustar | Va completa, sin recortar: una versión modificada no podría llamarse "Lilita". También en Flutter: `assets/fonts/LilitaOne-Regular.ttf` + `LilitaOne-OFL.txt`. |
| Fuente Fredoka (texto) | [google/fonts](https://github.com/google/fonts/tree/main/ofl/fredoka), The Fredoka Project Authors | SIL OFL 1.1 (sin nombre reservado) | Variable 300–700. En Rive va recortada a los caracteres del español y el inglés. En Flutter: `assets/fonts/Fredoka-Variable.ttf` + `Fredoka-OFL.txt`. |
| Formas, íconos, retratos, mascotas (la llama y el hondero), escenas de los niveles, la cortina y animaciones | Dibujados en el editor de Rive para este juego | Propios | Todo en vectores: no hay imágenes dentro del `.riv`. |

Las licencias OFL se muestran en la pantalla de licencias de la app (`LicenseRegistry` en `main.dart`). Descargadas el 19 de octubre de 2026 del repositorio oficial de Google Fonts.

Peso al cerrar la interfaz (Fase 8): el `.riv` ocupa 280 KB (130 KB comprimido) y la librería de Rive (`librive_native.so`), 7,3 MB instalada en arm64 (2,7 MB de descarga). El original editable vive en la nube de Rive (archivo "Guardianes UI"); en el repositorio solo está el exportado.

## Fuentes gratuitas que permiten uso comercial

Licencias revisadas en el sitio de cada fuente el 17 de octubre de 2026. Las condiciones pueden cambiar: **antes de usar un archivo, revisa la licencia de ese archivo en concreto** (no la del sitio) y guarda dónde lo descargaste.

| Fuente | Qué tiene | Licencia | Qué revisar |
|---|---|---|---|
| [Kenney](https://kenney.nl/assets) | Sprites, tilesets, UI, efectos | CC0 (dominio público) | Nada obligatorio; dar crédito es opcional. No usar su logo. |
| [OpenGameArt](https://opengameart.org) | Sprites, música, efectos | Cada archivo la suya: CC0, OGA-BY, CC-BY, CC-BY-SA, GPL | **Para Google Play, preferir CC0 u OGA-BY.** El propio sitio advierte que las tiendas de apps pueden chocar con GPL, CC-BY y CC-BY-SA (por las restricciones técnicas de las tiendas); para esas licencias, pedir permiso al autor. |
| [itch.io](https://itch.io/game-assets/free) | Paquetes de sprites y sonido | Cada paquete la suya (muchas licencias propias) | Leer la licencia de cada paquete: algunos piden crédito, otros prohíben uso comercial o revenderlos. |
| [Freesound](https://freesound.org) | Efectos y grabaciones | Por sonido: CC0, CC-BY 4.0 o CC-BY-NC | **Evitar CC-BY-NC** (no permite ganar dinero). Con CC-BY, dar crédito al autor. |
| [Pixabay](https://pixabay.com/music/) | Música y efectos | Licencia propia de Pixabay | Uso gratis y sin crédito; no se puede revender el archivo tal cual ni usar uno con marcas reconocibles. |
| [Incompetech](https://incompetech.com) (Kevin MacLeod) | Música | Creative Commons con crédito (o licencia de pago sin crédito) | Hay que acreditar cada tema con el texto que genera su sitio. |
| [Sonniss GameAudioGDC](https://sonniss.com/gameaudiogdc) | Grandes paquetes de efectos | Licencia propia: libres de regalías | Uso comercial sin crédito, en proyectos ilimitados. Son archivos grandes: recortarlos y convertirlos. |
| [ChipTone](https://sfbgames.itch.io/chiptone) | Generador de efectos | Lo que creas es CC0 | Nada. |
| [jsfxr](https://sfxr.me) | Generador de efectos (8 bits) | Uso comercial sin restricciones (versión gratis, exporta WAV) | Nada. |

### Créditos

Si usas algo con crédito obligatorio (CC-BY, OGA-BY, Incompetech…), anótalo en un `CREDITS.md` (autor, obra, licencia y enlace) desde el primer archivo: en la Fase 11 se muestra dentro del juego y va en la ficha de Google Play.
