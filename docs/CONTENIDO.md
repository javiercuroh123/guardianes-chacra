# Contenido del juego

Todo el contenido (guardianes, plagas, oleadas y niveles) son datos: agregar uno normal no requiere tocar código. El cargador (`lib/features/content/data/content_loader.dart`) lee estos archivos y avisa con el archivo y la ruta exacta si algo está mal, por ejemplo:

```
levels/andenes.json → waves[3].groups[0].pest: la plaga "gorgoja" no existe
```

Para comprobar el contenido después de editarlo:

```powershell
flutter test test/features/content
```

## Unidades

- **Distancias y alcances: casillas del mapa** (no píxeles). Velocidades: casillas por segundo.
- **Tiempos: segundos** (el motor los convierte a ticks; 30 ticks = 1 s).
- Los ids (nombres de archivo) usan solo minúsculas, números y `_`.

## Estructura

```
assets/content/
├─ index.json          idiomas y lista ordenada de guardianes, plagas y niveles
├─ rules.json          reglas generales de combate
├─ guardians/<id>.json
├─ pests/<id>.json
├─ levels/<id>.json
└─ i18n/<idioma>.json  nombres y fichas del Bestiario
assets/tiles/          mapas de Tiled (ver docs/TILED.md)
```

## index.json

| Campo | Tipo | Notas |
|---|---|---|
| `languages` | lista de textos | El primero es el idioma base (si falta un texto en otro idioma, se usa este). |
| `guardians`, `pests`, `levels` | listas de ids | El orden es el del Bestiario y el del mapa del valle. Sin repetidos. |

## rules.json

| Campo | Tipo | Ejemplo | Qué hace |
|---|---|---|---|
| `sellRefundRate` | número 0–1 | 0.7 | Fracción del maíz gastado en un guardián que se devuelve al venderlo (redondeado hacia abajo). |
| `minDamageFraction` | número 0–1 | 0.2 | Fracción del daño físico que siempre atraviesa la armadura. |

## pests/&lt;id&gt;.json

| Campo | Tipo | Obligatorio | Notas |
|---|---|---|---|
| `maxHealth` | número ≥ 1 | sí | |
| `speed` | número ≥ 0 | sí | Casillas por segundo. |
| `armor` | número ≥ 0 | no (0) | Se resta del daño físico. |
| `resistances` | objeto | no | Multiplicador por tipo de daño: `{"physical": 0.5, "fire": 1.5}` (0,5 = resiste la mitad; 1,5 = débil). |
| `cornReward` | entero ≥ 0 | sí | Maíz al derrotarla. |
| `potatoDamage` | entero ≥ 0 | sí | Papas que se come si llega a la collca. |
| `tags` | lista | sí | `ground` y/o `flying`. |
| `immunities` | lista | no | Tipos de efecto que no le afectan, por ejemplo `["slow"]`. |
| `abilities` | lista | no | Habilidades (ver abajo). |
| `boss` | true/false | no (false) | La última oleada de cada nivel debe traer un jefe. |
| `color` | `"#RRGGBB"` | no | Color de reemplazo para dibujarla si no tiene imagen. Sin él, se usa uno derivado del id. |
| `sprite` | objeto | no | Imagen animada: `{"image": "pests/gorgojo.png", "frames": 4, "fps": 8}` (ver `docs/ASSETS.md`). |

Fórmula de daño: `daño × resistencia del tipo × bonus contra sus etiquetas`; si es físico, `max(daño − armadura, daño × minDamageFraction)`. El fuego ignora la armadura.

### Habilidades de plagas

| `type` | Parámetros | Qué hace |
|---|---|---|
| `split_on_death` | `pest`, `count`, `spacing` (0,3) | Al ser derrotada (no al llegar a la collca) aparecen `count` plagas `pest` donde murió, escalonadas `spacing` casillas hacia atrás. Cuentan para la misma oleada. |
| `summon` | `pest`, `count`, `interval` (s), `spacing` (0,3) | Cada `interval` segundos invoca `count` plagas detrás de ella. |

## guardians/&lt;id&gt;.json

| Campo | Tipo | Notas |
|---|---|---|
| `defaultTargeting` | texto | Estrategia inicial: `first`, `last`, `strongest` o `closest` (el jugador la cambia). Por defecto `first`. |
| `color` | `"#RRGGBB"` | Opcional. Color de reemplazo hasta que tenga imagen; debe ser oscuro (contraste ≥ 3:1 con blanco) porque su inicial se dibuja en blanco. |
| `levels` | lista (≥ 1) | El primero se construye; los siguientes son las mejoras, en orden. |
| `branches` | lista (0 o ≥ 2) | La especialización final: después de la última mejora se elige una. Cada rama tiene además un `id`. |
| `unlock` | objeto | Opcional. Qué hace falta para poder construirlo (ver [Desbloqueos](#desbloqueos)). |
| `sprite` | objeto | Opcional. Imagen del guardián; cada nivel o rama puede tener la suya (ver `docs/ASSETS.md`). |

Cada nivel o rama tiene **todas** sus estadísticas (no solo las diferencias):

| Campo | Tipo | Notas |
|---|---|---|
| `cost` | entero ≥ 0 | Maíz para construir (primer nivel) o para mejorar a este nivel. |
| `range` | número ≥ 0 | Alcance en casillas. |
| `targets` | lista | Etiquetas a las que ataca: `ground`, `flying` (vacía para apoyo). |
| `behaviors` | lista | Ataques y auras (ver abajo). |

### Comportamientos de guardianes

| `type` | Parámetros | Qué hace |
|---|---|---|
| `projectile` | `damage`, `damageType` (`physical`/`fire`), `cooldown` (s), `projectileSpeed` (casillas/s); opcionales `splashRadius`, `bonusAgainst` (`{"flying": 2.5}`), `onHit` (efectos) | Lanza un proyectil teledirigido al objetivo que elige la estrategia. Con `splashRadius` daña a las plagas atacables cerca del impacto. |
| `area` | `damage`, `damageType`, `cooldown`; opcionales `bonusAgainst`, `onHit` | Golpea a la vez a todas las plagas atacables dentro del alcance. |
| `support_aura` | `attackSpeedBonus` (0,25 = +25 %) | No ataca: acelera a los demás guardianes dentro del alcance. Las auras no se suman (gana la mayor). |

### Efectos (`onHit`)

| `type` | Parámetros | Acumulación |
|---|---|---|
| `slow` | `factor` (0–1; 0,6 = 60 % de su velocidad), `duration` (s) | Gana el más fuerte; si es igual, queda la duración mayor; uno más débil se ignora. |
| `burn` | `damagePerSecond`, `duration` (s) | Daño de fuego en el tiempo. Queda el mayor daño por segundo y la duración no se acorta. |
| `stun` | `duration` (s) | Detiene a la plaga. Queda la duración mayor. |

Un comportamiento nuevo se programa como una clase que se registra en `lib/features/battle/domain/registry/core_behaviors.dart`; sus parámetros los valida el registro al crear la partida.

## levels/&lt;id&gt;.json

| Campo | Tipo | Notas |
|---|---|---|
| `map` | texto | Archivo en `assets/tiles/`. |
| `startingCorn` | entero ≥ 0 | |
| `startingPotatoes` | entero ≥ 1 | |
| `earlyCallCornPerSecond` | número ≥ 0 | Maíz por cada segundo de cuenta regresiva que se salta al llamar la oleada antes. |
| `waves` | lista (≥ 1) | Ver abajo. Cada nivel debe tener entre 10 y 15 oleadas y un jefe en la última (lo comprueba `real_content_test.dart`). |
| `unlock` | objeto | Opcional. Qué hace falta para poder jugarlo (ver [Desbloqueos](#desbloqueos)). |
| `music` | texto | Opcional. Música del nivel, ruta dentro de `assets/audio/` (ver `docs/ASSETS.md`). |

Cada oleada:

| Campo | Tipo | Notas |
|---|---|---|
| `prepTime` | segundos | Cuenta regresiva antes de empezar: la primera, desde el inicio del nivel; las demás, desde que terminó de aparecer la anterior. |
| `reward` | entero | Maíz al completarla (aparecieron todas sus plagas y no queda ninguna). |
| `groups` | lista (≥ 1) | `pest`, `count` (≥ 1), `path` (nombre de un camino del mapa), `delay` (s desde el inicio de la oleada, 0) e `interval` (s entre plagas, 0). |

## audio.json

| Campo | Tipo | Notas |
|---|---|---|
| `menuMusic` | texto | Música de los menús (ruta dentro de `assets/audio/`). |
| `sfx` | objeto | Efecto → archivo. Efectos: `shot`, `impact`, `pestDefeated`, `collcaDamaged`, `victory`, `defeat`, `boss`. Uno que falta no suena. |

## Desbloqueos

`"unlock"` en un nivel o un guardián. Si tiene las dos condiciones, se piden ambas; sin `"unlock"`, está abierto desde el principio.

| Campo | Tipo | Qué pide |
|---|---|---|
| `afterLevel` | id de nivel | Haber ganado ese nivel (al menos 1 estrella). |
| `totalStars` | entero ≥ 1 | Juntar esas estrellas entre todos los niveles (cada nivel cuenta su mejor marca). |

```json
"unlock": { "afterLevel": "andenes", "totalStars": 4 }
```

El cargador comprueba que cada regla se pueda cumplir: "juega" ganando con 3 estrellas cada nivel que se va abriendo y avisa si algo queda cerrado para siempre (por ejemplo, un nivel que se pide a sí mismo o más estrellas de las que existen). Al menos un guardián debe estar abierto desde el principio.

Lo desbloqueado queda guardado: si una actualización endurece una regla, el jugador no pierde lo que ya abrió. Valores actuales: Andenes tras la Chacra del Valle; Orilla del Lago tras Andenes y con 4 estrellas; Pututu tras la Chacra del Valle; Cóndor tras Andenes.

## i18n/&lt;idioma&gt;.json

Un objeto plano de clave → texto. Claves obligatorias:

```
pest.<id>.name                         pest.<id>.description
guardian.<id>.name                     guardian.<id>.description
guardian.<id>.branch.<rama>.name       guardian.<id>.branch.<rama>.description
level.<id>.name
```

Las claves que empiezan con `@` son notas y el juego las ignora. Los datos reales del mundo (por ejemplo, qué es un pututu) llevan una nota `"@<clave>": {"revisar": "..."}` en `es.json` hasta que alguien los verifique. Las descripciones son cortas y del mundo del juego, sin cifras inventadas.

## Cómo agregar…

- **Una plaga**: crea `pests/<id>.json`, agrega el id a `pests` en `index.json` y sus textos en cada idioma. Úsala en las oleadas.
- **Un guardián**: crea `guardians/<id>.json`, agrega el id a `guardians` en `index.json` y sus textos (incluidas las ramas). Si necesita un comportamiento que no existe, es código nuevo (una clase registrada), no un cambio en el motor.
- **Un nivel**: dibuja su mapa (ver `docs/TILED.md`), crea `levels/<id>.json`, agrega el id a `levels` y su nombre en cada idioma. Si no es el primero, dale un `unlock`.

## Lógica del balance inicial

Son valores de partida razonables para afinar con el simulador de balance (Fase 9) y con pruebas reales.

- **Referencia**: el gorgojo (30 de vida, 1 casilla/s) tarda unos 40 s en recorrer un camino de ~40 casillas.
- **Hondero nivel 1** (60 de maíz): 8 de daño cada 0,8 s = 10 de daño/s, alcance 3. Cubre ~6 casillas del camino → ~6 s de disparo por plaga → derrota a unos 2 gorgojos por pasada. El resto de los costos se escala por "daño por maíz" y por lo que aporta cada efecto.
- **Mejoras**: cada nivel sube el daño/s más que el costo, para que mejorar sea mejor que construir otro igual. Las ramas son caras y marcan un rol: más daño por golpe o más golpes.
- **Contrapesos** (cada plaga tiene un guardián que la resuelve):
  - Escarabajo (80 de vida, armadura 5, fuego ×1,5): el Hondero de nivel 1 le hace 3 por piedra; lo resuelven la Tullpa o la Piedra pesada.
  - Polilla (rápida, voladora): Hondero y Cóndor (×2,5 contra voladores). La Tullpa no la alcanza.
  - Langosta (enjambres de poca vida): daño en área (Tullpa, Llama).
  - Espíritu de la Helada (físico ×0,5, inmune a ralentizar, fuego ×1,5): la Tullpa.
  - Granizo (se parte en 3): área y fuego para los trozos.
  - Rey Gorgojo (600 de vida, armadura 2, invoca 2 gorgojos cada 10 s): necesita de todo; se come 8 de las 20 papas si llega.
- **Economía**: maíz inicial para 3 o 4 guardianes; las recompensas por plaga y por oleada alcanzan para un guardián o una mejora cada 1 o 2 oleadas. Llamar una oleada antes da 1,5 de maíz por segundo saltado.
- **Niveles**: Chacra del Valle (10 oleadas, 1 camino) presenta las plagas de a poco; Andenes (12 oleadas, 2 caminos) agrega el Granizo y el Espíritu de la Helada; Orilla del Lago (15 oleadas) tiene más voladores.

### Comprobación del nivel 1 (Fase 5)

`test/features/content/level_balance_test.dart` juega la Chacra del Valle sin gráficos con planes fijos de construcción. Con los valores iniciales, el Rey Gorgojo (900 de vida, armadura 4) y el Escarabajo (armadura 6) hacían que incluso una defensa completa ganara con 1 papa, así que se bajaron a los valores de arriba y se subió la recompensa de las oleadas 7 a 9. Resultado actual:

| Defensa | Resultado |
|---|---|
| Solo 3 Honderos | Pierde en la oleada 10 |
| 3 Honderos + Tullpa + 2 mejoras | Pierde en la oleada 10 |
| La mitad del plan de prueba | Gana con 9 papas |
| Invertir todo el maíz | Gana con 20 papas |
