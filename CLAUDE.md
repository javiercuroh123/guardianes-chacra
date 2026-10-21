# Guardianes de la Chacra — contexto maestro

Actúa como desarrollador senior de juegos móviles con Flutter y Flame, y como mi mentor. Vamos a construir juntos, por fases, un juego tower defense para publicar en Google Play Store. El plan completo de fases está en `../prompt-tower-defense.md`.

## El juego
- Nombre de trabajo: "Guardianes de la Chacra" (en inglés, "Guardians of the Chacra").
- Historia: en un valle andino mágico, plagas y espíritus del mal clima bajan de las montañas para devorar la cosecha de papas guardada en la collca (almacén andino). El jugador coloca guardianes a lo largo del camino para detenerlos.
- Estilo caricaturesco y colorido, para todas las edades. Orientación horizontal. Niveles de 5 a 8 minutos. Funciona sin internet.

## Reglas base
- Moneda: granos de maíz. Se ganan al derrotar plagas y al completar oleadas.
- Vidas: papas en la collca. Cada plaga que llega se come papas; si llegan a 0, pierdes.
- Los guardianes se construyen solo en espacios fijos del mapa.
- Cada nivel tiene entre 10 y 15 oleadas; la última incluye un jefe.
- Al ganar recibes de 1 a 3 estrellas según las papas que te queden. Las estrellas desbloquean niveles y guardianes.
- Se puede llamar la siguiente oleada antes de tiempo a cambio de maíz extra, y acelerar el juego a x2.

## Contenido inicial (MVP)
Guardianes (torres), cada uno con 2 mejoras y una especialización final a elegir entre 2 ramas:
- Hondero: barato, disparo rápido a un objetivo, daño físico, ataca tierra y aire.
- Llama: escupitajo que ralentiza a las plagas en un área pequeña, poco daño.
- Tullpa (fogón andino): daño de fuego en área con quemadura, corto alcance, solo plagas de tierra.
- Cóndor: largo alcance, especialista contra voladores.
- Pututu: apoyo, no ataca; aumenta la velocidad de ataque de los guardianes cercanos.

Plagas (enemigos):
- Gorgojo: básico y lento.
- Polilla: rápida, frágil y voladora.
- Langosta: llega en enjambres numerosos.
- Escarabajo acorazado: mucha armadura física, débil al fuego.
- Espíritu de la Helada: inmune a la ralentización y resistente al daño físico.
- Granizo: al ser destruido se divide en granizos pequeños.
- Jefe Rey Gorgojo: mucha vida, invoca gorgojos cada cierto tiempo.

Niveles: 3 mapas para empezar, con dificultad creciente: Chacra del Valle, Andenes (con 2 caminos) y Orilla del Lago.
Bestiario: enciclopedia donde se desbloquea la ficha de cada plaga y guardián al encontrarlo por primera vez.

## Mi entorno
- Windows 10, VS Code, Flutter 3.47.2 (Dart 3.13.2). Dame los comandos de terminal para Windows (PowerShell).
- Pruebo en un celular Android físico conectado por USB: Redmi Note 14 Pro (MediaTek Helio G100, 8 GB, Android 16, 2400×1080 = 853×384 dp en horizontal), id `9d6tcq9tz5jfdmrk`. También en Chrome. El rendimiento (60 FPS con 100+ plagas) se valida en ese celular.
- applicationId: `com.javiercuroh.guardianeschacra` (permanente una vez publicado).
- Soy estudiante de Ingeniería de Software con IA. Ya hice apps en Flutter con Firebase y Supabase, y un juego puzzle con Flame (Sabor Fusión, en `../sabor_fusion`); estoy aprendiendo Flame.

## Requisitos de escalabilidad (obligatorios)
1. Simulación en Dart puro: la lógica del juego (plagas, guardianes, oleadas, economía, daño) vive en la capa domain, sin depender de Flame ni de Flutter. Usa un paso de tiempo fijo y un generador aleatorio con semilla, para que la simulación sea determinista, testeable y pueda ejecutarse sin gráficos.
2. Arquitectura por features con capas separadas: domain (simulación y reglas), data (carga de contenido y persistencia), presentation (Flame + widgets). Flame solo dibuja el estado y envía las acciones del jugador.
3. Contenido 100% por datos: guardianes, plagas, mejoras, oleadas y niveles se definen en JSON dentro de assets. Los mapas se diseñan en Tiled, con capas de objetos para caminos, espacios de construcción y la collca. Agregar un guardián, una plaga o un nivel normal no debe requerir tocar el motor.
4. Composición sobre herencia: los comportamientos (estrategia de apuntado, tipo de ataque, efectos de estado como ralentizar o quemar, habilidades especiales de las plagas) son piezas reutilizables que se combinan desde el JSON mediante un registro de tipos. Un comportamiento nuevo se agrega como una clase nueva registrada, sin modificar las existentes.
5. Bus de eventos: la simulación emite eventos (plaga derrotada, guardián disparó, collca dañada, oleada iniciada) y las demás capas (gráficos, audio, analítica, logros) se suscriben a ellos.
6. Servicios externos (persistencia, audio, anuncios, analítica, logros) detrás de interfaces abstractas, con una implementación local o "falsa" por defecto.
7. Gestión de estado con Riverpod para menús, HUD y progreso; la partida en sí avanza dentro del game loop de Flame.
8. Textos preparados para localización (español e inglés) con archivos ARB desde el principio.
9. Rendimiento: 60 FPS estables en un Android de gama media con al menos 100 plagas y sus proyectiles en pantalla. Usa pools de objetos para proyectiles y efectos.
10. Tests unitarios de la simulación y `flutter analyze` sin warnings.

## Decisiones acordadas (Prompt 0)

### Estructura de carpetas
```
guardianes_chacra/
├─ assets/
│  ├─ content/
│  │  ├─ index.json   idiomas y lista ordenada de guardianes, plagas y niveles
│  │  ├─ rules.json   reglas generales de combate
│  │  ├─ guardians/   un JSON por guardián (estadísticas, costo, comportamientos, mejoras y ramas)
│  │  ├─ pests/       un JSON por plaga
│  │  ├─ levels/      un JSON por nivel (mapa, maíz, papas y oleadas)
│  │  └─ i18n/        es.json, en.json: nombres y fichas del bestiario, buscados por id
│  └─ tiles/          mapas de Tiled (.tmx) + tileset de placeholder (.tsx + .png), juntos
├─ lib/
│  ├─ main.dart
│  ├─ app/            App, arranque, ThemeData, navegación
│  ├─ core/
│  │  ├─ events/      EventBus (Dart puro)
│  │  ├─ math/        Vec2, generador aleatorio con semilla (Dart puro)
│  │  └─ services/    interfaces de audio, analítica, anuncios y logros + implementaciones falsas
│  ├─ l10n/           app_es.arb, app_en.arb (solo textos de la interfaz)
│  └─ features/
│     ├─ content/     domain: definiciones (GuardianDef, PestDef, WaveDef, LevelDef, MapDef)
│     │               data: lector de JSON, lector de mapas de Tiled y validador
│     ├─ battle/      domain: la simulación · presentation: FlameGame, componentes, pools, menú radial, HUD, overlays
│     ├─ progress/    domain: repositorio y reglas de desbloqueo · data: implementación local y migraciones
│     ├─ level_select/  presentation
│     ├─ bestiary/    presentation
│     ├─ settings/    domain · presentation (se guardan con el progreso)
│     └─ menu/        presentation
├─ tool/              simulador de balance por línea de comandos (Fase 9)
└─ test/              espejo de lib/ + test/architecture/
```

Dentro de `battle/domain/`:
```
engine/      Simulation (step), comandos del jugador
world/       estado: Pest, Guardian, Projectile, PathTrack, BuildSlot, Collca, economía
behaviors/   targeting/ (first, last, strongest, closest) · attacks/ (projectile, area, support_aura)
             effects/ (slow, burn, stun) · abilities/ (split_on_death, summon)
registry/    BehaviorRegistry: traduce "slow" → SlowEffect.fromJson
waves/       WaveSpawner
events/      sealed class SimEvent (PestSpawned, PestDefeated, GuardianFired, CollcaDamaged, WaveStarted…)
```

`content` va aparte de `battle` porque el Bestiario y la selección de nivel leen las definiciones de plagas y niveles sin depender de la simulación.

### Simulación y renderizado
- `Simulation` es Dart puro y avanza con `step()`: exactamente un tick de duración fija (propuesta: 30 ticks/s; se justifica en la Fase 2). No conoce Flame, ni el reloj real, ni la pantalla.
- El jugador no modifica el estado: envía comandos (`Build`, `Upgrade`, `Sell`, `SetTargeting`, `CallNextWave`) que se aplican al inicio del siguiente tick. Semilla + comandos con su tick = partida reproducible (tests, simulador de balance, reproducir bugs).
- Flame es solo el reloj: en `update(dt)` suma `dt × velocidad` a un acumulador y llama `step()` por cada paso completo, con un tope de pasos por frame para no congelarse si el teléfono se traba. x2 = el doble de pasos con el mismo dt (resultado idéntico a x1). Pausa = no llamar `step()`.
- Los componentes leen el estado en solo lectura y dibujan interpolando entre el tick anterior y el actual (`alpha = acumulador / paso`).
- El bus de eventos es sincrónico (sin Streams, para no romper el determinismo). Gráficos, audio, logros y analítica se suscriben. El HUD (Riverpod) se actualiza desde los eventos, no en cada frame.
- Un test de arquitectura falla si algo en `domain/` importa Flutter, Flame o Riverpod, o depende de `data/` o `presentation/`.

### Otras decisiones
- Determinismo: generador aleatorio propio con semilla y aritmética de 32 bits, porque `Random(semilla)` de Dart no garantiza la misma secuencia en la VM y en la web. En la simulación se comparan distancias al cuadrado y se evita la trigonometría. El determinismo se garantiza dentro de una misma plataforma (los tests y el simulador corren en la VM de Dart).
- Tiled: `flame_tiled 3.1.2` exige `tiled ^0.11` (aunque ya existe la 0.12). El paquete `tiled` es Dart puro, así que el lector de mapas de la capa data funciona en tests y en el simulador sin Flutter. Los archivos se leen a través de una interfaz: `rootBundle` en la app y `dart:io` en las herramientas.
- Los voladores siguen los mismos caminos que las plagas de tierra. Un camino aéreo propio se podrá agregar después en Tiled sin tocar código.
- Aturdir no lo usa ningún guardián base; lo tendrá alguna rama de especialización (se define con los JSON en la Fase 4).
- Textos: los ARB son solo para la interfaz (gen-l10n genera getters fijos y no busca por clave). Los nombres y las fichas del Bestiario van en `assets/content/i18n/<idioma>.json`, por id.
- Datos reales en el Bestiario (por ejemplo, sobre el gorgojo de los Andes): marcados `"revisar"` hasta que yo los revise, y sin cifras inventadas.
- Flame + Riverpod sin `flame_riverpod`, como en Sabor Fusión: la pantalla de la partida conecta el juego con los providers; Flame no conoce Riverpod ni las reglas.
- Lints: `very_good_analysis` (sin `public_member_api_docs` ni `discarded_futures`). TODOs con el formato `// TODO(fase-N): ...`.
- En Windows, no editar archivos con `Get-Content`/`Set-Content` de PowerShell 5.1: los lee como ANSI y rompe los acentos UTF-8.
- Sintaxis de Dart 3.13 que exige el lint: `const new(...)`, `const new _(...)`, `factory nombre(...)`, `this._campo` en parámetros con nombre (el que llama usa `campo:`) y, en los enums, `new(...)` sin `const`.

### Simulación (Fase 2)
- 30 ticks por segundo (`sim_time.dart`). El tiempo se cuenta en ticks enteros; los segundos de los datos se convierten una vez con `secondsToTicks` (redondeo).
- Unidad del mundo = 1 casilla del mapa: velocidades en casillas/s y alcances en casillas.
- Orden de un tick en `Simulation.step()`: comandos → movimiento y llegadas a la collca → derrota → nuevas plagas → oleadas completadas → victoria. Una plaga que aparece en el tick N empieza a moverse en el N+1.
- Oleadas (`WaveSpawner`): la cuenta regresiva de la primera empieza con el nivel; la de las demás, cuando la anterior terminó de aparecer (no se superponen al aparecer). `delay` e `interval` de cada grupo se cuentan desde el inicio de la oleada. Una oleada se completa cuando aparecieron todas sus plagas y no queda ninguna viva; ahí se paga `reward`.
- Llamar la siguiente oleada (`CallNextWave`) solo vale con cuenta regresiva activa y da `floor(segundos restantes × earlyCallCornPerSecond)`; si no, emite `CommandRejected(noWaveWaiting)`.
- Las papas nunca bajan de 0. La derrota se evalúa antes que la victoria, en el mismo tick. Con la partida terminada, `step()` no hace nada.
- La capa visual lee las plagas como `PestView` (solo lectura). La cuenta regresiva y la bonificación se leen del estado (`nextWaveCountdownTicks`, `earlyCallBonus`), no de eventos, porque cambian en cada tick.
- `SeededRandom` (Mulberry32 en 32 bits) coincide con la implementación canónica de JavaScript; su test fija la secuencia de referencia (comprobado con `dart compile js` + `node`, porque `flutter test --platform chrome` no conecta en este equipo). Hasta la Fase 3 ninguna regla usa azar.
- Los eventos (`sim_events.dart`) tienen igualdad por valor para poder comparar partidas completas en los tests.

### Combate (Fase 3)
- `GuardianDef.levels`: bloques completos (no diferencias). El primero se construye y los demás son mejoras; `cost` es lo que cuesta construir o mejorar a ese nivel. Después de la última mejora se elige una de `branches` con `SpecializeGuardian` (`UpgradeGuardian` responde `chooseBranch`).
- `BattleRules` (`sellRefundRate`, `minDamageFraction`) son valores de balance; la simulación los recibe obligatoriamente. Vender devuelve `floor(totalSpent × sellRefundRate)`.
- Daño (`damageDealt`): × resistencia del tipo × `bonusAgainst` por etiqueta; si es físico, `max(d − armadura, d × minDamageFraction)`. El fuego ignora la armadura.
- Efectos: uno por tipo por plaga; cada efecto define su acumulación en `mergeInto` (ralentizar: gana el más fuerte, si es igual queda la duración mayor, uno más débil se ignora; quemar: mayor daño/s y duración máxima; aturdir: duración máxima). Un efecto aplicado en el tick T actúa en los ticks T+1…T+N. Inmunidades: `PestDef.immunities` con el `type` del efecto.
- Auras (`attackSpeedBonusFor`): no se suman, gana la mayor. `Cooldown` empieza listo y descuenta `attackSpeedMultiplier` por tick.
- Proyectiles teledirigidos: sin área solo dañan a su objetivo si sigue vivo; con `splashRadius` dañan a las plagas atacables (etiquetas del guardián que lo lanzó) cerca del impacto.
- Composición: `BehaviorRegistry` (estrategias, comportamientos de guardián, efectos y habilidades) + `BehaviorParams` (errores con el formato `tipo: detalle`). Los de serie se registran en `core_behaviors.dart`. Los comportamientos solo hablan con el motor a través de `BattleContext`; `Simulation` lo implementa en un objeto privado para que la capa visual no pueda llamar a `hit` ni a `spawnPest`.
- Toda plaga nueva (de la oleada, dividida o invocada) y todo proyectil nuevo empiezan a moverse en el tick siguiente. Los trozos y las invocadas cuentan para la oleada de su madre. El orden completo de un tick está documentado en `Simulation`.
- `Simulation` valida al crearse los comportamientos y la estrategia por defecto de cada guardián, las habilidades de las plagas (y las plagas que crean) y los espacios con id repetido.
- Los comandos están en `simulation_commands.dart` (`part` + extensión `_Commands`); `step()` la llama con `this._applyCommands()`.
- En los tests de la simulación, acotar todo `while` con un máximo de ticks (si la partida termina, `step()` no avanza y el bucle no sale) y usar `flutter test --timeout 30s`.

### Contenido y mapas (Fase 4)
- Esquemas, cómo agregar contenido y lógica del balance: `docs/CONTENIDO.md`. Tiled (instalación, capas, ejercicio): `docs/TILED.md`. Tiled 1.12.2 (`winget install --id Tiled.Tiled`).
- El id de una plaga, guardián o nivel es el nombre de su archivo (minúsculas, números y `_`) y debe estar en `assets/content/index.json`, que fija el orden (Bestiario y mapa del valle). Agregar contenido no toca `pubspec.yaml`.
- `ContentLoader` (Dart puro, recibe un `AssetSource`) valida tipos, rangos, etiquetas, referencias a plagas y caminos, ramas (0 o ≥ 2) y textos en todos los idiomas, con errores `archivo → ruta: detalle` (`JsonNode`). Los parámetros de los comportamientos los valida el registro al crear la `Simulation`; `real_content_test.dart` crea una partida con cada nivel real, la juega sin guardianes y construye cada guardián.
- `FileAssetSource` (`dart:io`) es para tests y herramientas: la app no debe importarlo (no compila en web). La versión con `rootBundle` llega en la Fase 5.
- Mapas: casillas cuadradas de 64 px, 26 × 12. Capas `terreno` (dibujo), `caminos` (polilíneas con nombre = id), `espacios` (puntos; id = nombre o `espacio_<id>`) y `collca` (un punto). Cada camino debe terminar a ≤ 0,75 casillas de la collca. `tiled` es dependencia directa (^0.11.1, la que fija flame_tiled). El `.tmx`, el `.tsx` y el `.png` van juntos en `assets/tiles/`; en la Fase 5 se cargan con `Images(prefix: 'assets/tiles/')` para que Tiled y Flame lean los mismos archivos.
- `LevelDef` = `id`, `mapFile`, `map` (`MapDef`: tamaño, collca, caminos y espacios) y la economía y las oleadas. `PestDef.boss` marca al jefe; la última oleada de cada nivel debe traer uno (lo comprueba el test del contenido real).
- Textos del contenido: claves de `ContentTexts` (`pest.<id>.name`, `guardian.<id>.branch.<rama>.description`…). `es.json` es el idioma base y lleva las notas `"@clave": {"revisar": ...}` de los datos reales.
- `tool/generate_placeholder_maps.py` y `tool/generate_placeholder_tileset.py` (Python sin dependencias) crearon los mapas y el tileset de prueba; el de mapas no sobrescribe sin `--force`, porque una vez editado en Tiled el `.tmx` es el original.
- Ojo con los lints: la palabra "Todo" al inicio de un comentario dispara `flutter_style_todos`.
- `"color": "#RRGGBB"` (opcional) en guardianes y plagas: color de reemplazo hasta los sprites de la Fase 8. Sin él, `colorForId` deriva uno del id (FNV-1a, no `String.hashCode`). Los guardianes llevan colores oscuros (contraste ≥ 3:1 con su inicial blanca; lo comprueba el test del contenido real).

### La partida en pantalla (Fase 5)
- `BattleGame` (Flame) solo hace de reloj, dibujo y toques: `FixedStepClock` → `simulation.step()`; los eventos crean y quitan componentes; los toques se avisan con `onSlotTapped`/`onGuardianTapped`/`onEmptyTapped`. `onChanged` avisa como mucho una vez por frame que cambió el HUD o un guardián.
- Interpolación (mixin `Interpolated`): `rememberPrevious()` justo antes del último paso del frame y `readCurrent()` después; se dibuja un tick atrasado. Mundo = 64 px por casilla (`BattleGame.tileSize`).
- Cámara: `MapFit` (zoom y origen) encaja el mapa completo; se aplica en cada `onGameResize` (también antes de cargar) y en `onLoad` con `canvasSize`. En la web `size` todavía vale 0 durante `onLoad` (zoom 0 = mapa invisible).
- Pools: el `ComponentPool` de Flame (`acquire()` + `world.add`; `removeFromParent()` lo devuelve solo) para proyectiles y anillos (`PulseComponent`).
- Menús: widgets de Flutter (`BuildMenu`/`GuardianMenu` en `menus/battle_menus.dart`, sobre `RadialMenu`/`RadialButton`) encima del `GameWidget`, ubicados con `MapFit.toScreen`. Arman cada opción como `MenuChoice` (id, alcance, comando); `BattleScreen` guarda la selección y confirma. Primer toque = vista previa (alcance + "Toca otra vez para confirmar"), segundo = comando. Claves: `build-<id>`, `menu-upgrade`, `menu-branch-<id>`, `menu-sell`, `menu-targeting`. Al terminar la partida se limpia la selección.
- El HUD mínimo, el aviso de fin y el botón "Jugar" que abría el primer nivel fueron provisionales: los reemplazó la Fase 6.
- `material.dart` exporta otra `Simulation` (física): importarlo con `hide Simulation` donde se use la nuestra.
- Tests con Flame: el mapa se carga fuera del reloj falso (`preloadMap` usa `runAsync`; decodificar el tileset no funciona con el reloj falso) y se pasa con `loadMap`; un componente no puede estar en dos juegos (precargar uno por partida). `advance()` llama a `game.update` directamente. Tocar el mapa con `tapMap` (espera 50 ms: el detector de toques de Flame deja un temporizador de 40 ms). Nunca `pumpAndSettle`.
- Balance: desde la Fase 9 lo mide el simulador (ver abajo). En la Fase 5 se bajaron el Rey Gorgojo (600 de vida, armadura 2, 8 papas) y el Escarabajo (80, armadura 5) y se subieron las recompensas de las oleadas 7 a 9 del nivel 1 (detalle en `docs/CONTENIDO.md`).
- En el Redmi, el `SafeArea` deja ~39 dp a la izquierda (la cámara frontal): el mapa ocupa el resto (zoom ≈ 0,49).

### Menús, progreso y pantallas (Fase 6)
- Flujo: título (Jugar / Bestiario / Ajustes) → valle (`LevelSelectScreen`) → vista previa (`LevelPreviewScreen`) → partida (`pushReplacement`). "Volver al valle" y "Salir del nivel" hacen `maybePop`; "Siguiente nivel" reemplaza la partida por la vista previa del siguiente.
- Estrellas: `starsFor` (dominio) con `twoStarsFraction`/`threeStarsFraction` de `rules.json` (0,5 y 0,9 de las papas iniciales; cualquier victoria = 1). `Progress` (inmutable) guarda la mejor marca por nivel y las plagas y guardianes descubiertos. Desbloqueos: ver Fase 7.
- Progreso y ajustes: `progressProvider` y `settingsProvider` (`Notifier`), guardados desde la Fase 7. Idioma: Sistema/Español/English; `localeFor` da `null` para "Sistema".
- Descubrimientos: una plaga al aparecer (`PestSpawned`), un guardián al construirlo (`GuardianBuilt`). Los escucha `BattleScreen` (no el juego: no son dibujo), igual que `LevelWon` (guarda las estrellas) y `LevelLost`.
- `BattleStats` (dominio) cuenta el maíz cosechado: todo `CornChanged` positivo menos lo que devuelve vender (`GuardianSold.refund`).
- HUD completo: maíz, papas, oleada; botón de siguiente oleada (segundos con `ticksToWholeSeconds` y `+bono`, solo si hay cuenta regresiva), x1/x2 (`clock.speed`) y pausa. `BattleGame` avisa `onChanged` cuando cambian los segundos o el bono. Claves: `hud-next-wave`, `hud-speed`, `hud-pause`.
- Pausa, victoria y derrota son overlays de Flame (`overlayBuilderMap`, nombres en `BattleOverlays`). Con un overlay activo se ocultan el HUD y los menús. Claves: `pause-resume`, `victory-next`, `battle-retry`, `battle-exit`.
- Pausa = `pauseEngine()`. Al pasar a segundo plano (`AppLifecycleListener.onHide`) se pausa con el overlay; como `pauseEngine()` borra la marca de "pausado por segundo plano" de Flame, al volver no se reanuda solo.
- Tema central `AppTheme.light` (verde chacra, maíz, terracota, crema) + `GameColors` (HUD, velo, estrellas, valle); `app_theme_test.dart` mide el contraste AA. Botones del tema: mínimo 200 × 48. `IconButton.foregroundColor` no colorea un `Text` dentro del botón: darle su color.
- La vista previa ordena las plagas por primera aparición (`pestsAppearingIn`; `List.sort` de Dart no es estable: desempatar por índice).
- Tests: el ciclo de vida de la app se simula con un mensaje `flutter/lifecycle` (`setLifecycle` en `battle_screen_test.dart`). La tarjeta de los overlays une sus textos en un solo nodo de accesibilidad: buscar con `RegExp`.

### Progresión y guardado (Fase 7)
- Reglas de desbloqueo en los datos: `"unlock": {"afterLevel": "<nivel>", "totalStars": N}` (opcional, una o ambas) en cada nivel y guardián → `UnlockRule` (content/domain, `isMetBy(stars)`). Valores: Andenes tras la Chacra del Valle; Orilla del Lago tras Andenes + 4 estrellas; Pututu tras la Chacra del Valle; Cóndor tras Andenes. `ContentLoader` valida campos, referencias y que todo sea alcanzable (gana con 3 estrellas lo que se va abriendo); al menos un guardián abierto al empezar.
- `Progression` (progress/domain): abierto = ya guardado en `Progress.unlockedLevels/unlockedGuardians` ∪ cumple hoy su regla (lo ganado no se pierde si una actualización endurece una regla). `record()` anota el resultado, guarda todo lo abierto y devuelve lo recién abierto (`Unlocked`), que la victoria muestra ("¡Desbloqueaste: …!").
- El bloqueo lo aplica el motor: `BattleScreen` le pasa a la `Simulation` solo los guardianes desbloqueados (otro tipo → `unknownGuardianType`) y el menú radial muestra solo esos. El simulador de balance juega cada nivel con los guardianes que el jugador tendría al llegar (`guardiansAvailableAt`).
- El aviso de nivel bloqueado dice la regla (`valleyLockedLevel/Stars/Both`).
- Guardado: `ProgressRepository` (domain) con `SaveData` = progreso + ajustes, un solo documento. `SaveCodec` (data, Dart puro): JSON `{"version", "progress", "settings"}`; la versión actual es `saveMigrations.length + 1` (v1 = primer formato, todavía sin migraciones); los campos que faltan toman su valor por defecto; JSON roto, tipo inesperado o versión futura → `SaveFormatException`.
- `LocalProgressRepository`: `SharedPreferencesAsync` (la API que recomienda shared_preferences; la clásica quedará obsoleta), clave `guardianes.save`; un guardado ilegible se copia a `guardianes.save.backup` y se empieza de cero; las escrituras van en cola. `MemoryProgressRepository` es la implementación por defecto (tests).
- Arranque: `main.dart` lee el guardado antes de `runApp` y lo pasa con overrides (`progressRepositoryProvider`, `savedGameProvider`); los controladores arrancan de ahí. `autosaveProvider` (`lib/app/autosave.dart`, lo mantiene vivo `GuardianesApp`) guarda cuando cambian progreso o ajustes; los controladores no saben de disco.
- Tests del guardado: `InMemorySharedPreferencesAsync` de `shared_preferences_platform_interface` (dev, ^2.4.2). Un `const {}` sin tipo es `Map<dynamic, dynamic>` y no pasa `is Map<String, Object?>`.
- Partida a medias: no se guarda (decisión de la Fase 7). Si se pide, la opción recomendada es guardar semilla + comandos con su tick y re-simular, con un hash del contenido para descartar si cambió el balance.

### Arte, sonido y game feel (Fase 8)
- Audio detrás de `AudioService` (`core/services`): `SilentAudioService` por defecto (tests) y `FlameAudioService` (flame_audio ^2.12.2: `FlameAudio.bgm` para la música, un `AudioPool` por efecto). `main.dart` lo pone con `audioServiceProvider`. Las órdenes a la música (y `bgm.initialize()`) van en una fila: en Android `setAudioContext` detiene un reproductor que ya suena. Un archivo que falta queda mudo y se avisa una vez.
- Datos: `assets/content/audio.json` (`menuMusic` y `sfx`: `shot`, `impact`, `pestDefeated`, `collcaDamaged`, `victory`, `defeat`, `boss`) y `"music"` en cada nivel; rutas dentro de `assets/audio/`. `audioDirectorProvider` (`lib/app/audio.dart`) conecta Ajustes (música/efectos) y, al cargar el contenido, precarga todo y toca la música del menú.
- `BattleFeedback` (battle/presentation/feedback) escucha los eventos de la simulación: efectos (los frecuentes pasan por `SoundLimiter`: 70 ms por sonido y 6 cada 250 ms), música del nivel (se corta al ganar o perder) y vibración (`HapticsService` desde la Fase 9, solo con el ajuste encendido; la de la collca, cada 300 ms como mucho). `BattleScreen` pausa y reanuda la música con la pausa y vuelve a la del menú en `dispose` (el servicio se guarda en un `late final`: en `dispose` ya no se puede leer de Riverpod).
- Sprites: `"sprite": {"image", "frames", "fps"}` (`SpriteDef`) en plagas, guardianes y cada nivel o rama (`GuardianDef.spriteAt`). Tira horizontal de cuadros cuadrados en `assets/images/` (128 px por casilla, el jefe 192). Las plagas se espejan al ir a la izquierda; sin imagen o si no carga, se dibuja la forma. Solo el gorgojo tiene sprite (placeholder de `tool/generate_placeholder_sprites.py`).
- `BattleAssets` reemplaza a `LoadMap`: carga el mapa y las imágenes (`BattleGame.battleAssets`; `assets` choca con `Game.assets` de Flame). Tests: `preloadAssets(tester, level, images: spriteImagesOf(content))` los carga con `runAsync`.
- Game feel en `BattleGame`: destello blanco al recibir daño (`PestComponent.flash`), números de daño opcionales (ajuste `damageNumbers`, apagado; se acumula el daño de cada plaga y se muestra cada 0,3 s, pool con tope de 24), partículas al derrotar (tope 10 estallidos) y sacudida de cámara al aparecer el jefe (0,5 s; no con `MediaQuery.disableAnimations`).
- Placeholders sin licencias de terceros: `tool/generate_placeholder_audio.py` (WAV sintetizados, pentatónica de La) y el sprite del gorgojo. Lista de assets, formatos y fuentes con licencias verificadas: `docs/ASSETS.md` (para Google Play, en OpenGameArt preferir CC0 u OGA-BY).
- `real_content_test.dart` comprueba que cada sonido y sprite nombrado exista, que su carpeta esté en `pubspec.yaml` y que el sprite se divida en sus cuadros.
- En el Redmi (HyperOS): `log.tag` vale "M" y oculta `I/flutter`; `adb shell setprop log.tag.flutter V` lo muestra (se pierde al reiniciar). `dumpsys audio` muestra los reproductores como "idle" aunque suenen: la señal es el evento "format update" (la música del menú se repite cada 12,8 s, la de batalla cada 8 s).

### Herramientas, balance, accesibilidad y CI (Fase 9)
- Herramientas de desarrollo en `lib/dev/`, activas con `devToolsEnabled = !kReleaseMode` (debug y profile; en profile se mide el rendimiento y hace falta el botón de estrés). Botón 🐞 del HUD (`hud-dev`) → `DevPanel` en una hoja con `isScrollControlled` (en horizontal la normal no alcanza): maíz infinito, invencible, superposición (caminos, alcances, FPS, conteos), saltar oleada, estrés. En Ajustes, "Desarrollo: todo desbloqueado" (`devOptionsProvider`, no se guarda).
- Trucos en la simulación: `SimulationCheats` (`infiniteCorn`, `invincible`), consultados solo en `canAfford`/`_spendCorn` y al perder papas. Comandos de desarrollo `SkipWave` y `StressTest(count)` (una plaga del primer tipo del nivel cada 2 ticks, alternando caminos).
- Simulador de balance: `dart run tool/balance.dart` → `build/balance/balance.csv` y tabla. Motor en `lib/dev/balance/autoplay.dart` (Dart puro): 4 estrategias genéricas (`minima`, `honderos`, `mixta`, `mejoras`) que eligen espacios por cobertura del camino, turnándose entre caminos (`rankSlotsByCoverage`). Resultados, lectura y propuestas: `docs/BALANCE.md`. Las propuestas no se aplican sin aprobación. `level_balance_test.dart` usa `runBalance`.
- Estrés: `dart run tool/stress.dart` (`lib/dev/stress.dart`): 15 guardianes (agrega espacios si el mapa no tiene) y 150 plagas, ms por tick (promedio, p95, máximo; presupuesto p95 ≤ 2 ms). Cómo medir en el teléfono (profile, overlay `P`, DevTools): `docs/RENDIMIENTO.md`.
- Vibración detrás de `HapticsService` (`core/services`), como el audio: `SilentHapticsService` por defecto, `SystemHapticsService` en `main.dart` (`hapticsServiceProvider`). Tests: `FakeHapticsService`.
- Letra grande: `clampAppTextScale` en el `builder` de `MaterialApp` (y de `testApp`) limita todo a 2×; el HUD y `RadialMenu` se limitan a 1,3× (`TextScaleLimits`). Los datos del HUD se achican (`FittedBox`) si no caben. `text_scale_test.dart` monta cada pantalla y overlay a 1,3× y 2× en 853 × 384 (un desborde hace fallar el test). Cambiar la letra en un test: `tester.platformDispatcher.textScaleFactorTestValue`.
- Efectos de estado con forma propia (`EffectMarks`): lento = anillo punteado, quemadura = corona de puntas, aturdido = tres puntos girando sobre la cabeza. Marcas y números de daño en dos tonos (borde `BattleColors.effectBorder` debajo); `battle_colors_test.dart` comprueba contraste ≥ 3:1 contra cada suelo del tileset.
- CI: `.github/workflows/ci.yml` (checkout@v7, subosito/flutter-action@v2 con Flutter 3.47.2): `flutter gen-l10n` (los `app_localizations*.dart` no se suben), `dart format --set-exit-if-changed lib test tool`, `flutter analyze`, `flutter test`. Todavía no hay repositorio en GitHub.
- Prueba manual en un teléfono antes de cerrar una fase: `docs/PRUEBAS_MANUALES.md`.

### Anuncios, consentimiento y analítica (Fase 10)
- `google_mobile_ads` ^9.1.0 (trae el SDK de consentimiento UMP). `AdsService` (`core/services`): `NoAdsService` por defecto (tests) y `GoogleAdsService` en `main.dart` (`adsServiceProvider`). Orden: `requestConsentInfoUpdate` → `loadAndShowConsentFormIfRequired` → solo con `canRequestAds()` se inicializa el SDK (con `maxAdContentRating: G`) y se precargan un recompensado y un intersticial (reintento a los 30 s). `status` (`ValueListenable<AdsStatus>`): `rewardedReady` y `privacyOptionsRequired`; las pantallas usan `ValueListenableBuilder`.
- IDs (`AdUnitIds.forThisBuild`): fuera de release siempre los de prueba de Google; en release, los de `--dart-define-from-file=admob.json` (o sin anuncios si faltan). App ID: `android/admob.properties` → `manifestPlaceholders["admobAppId"]` (sin el archivo, el de prueba). Los reales están en `.gitignore`; hay `.example`. Formulario como en Europa: `--dart-define=UMP_TEST_DEVICE=<id hasheado>`.
- Valores en `assets/content/ads.json` (`AdsDef`, validado por `ContentLoader`): `rewardedStartCorn` 50, `rewardedRevivePotatoes` 5, `interstitialEveryLevels` 3; 0 apaga cada parte.
- Simulación: `Simulation(extraCorn:)` y `revive(potatoes)` (método, no comando: con la partida perdida no corren ticks; una vez por partida, `canRevive`, evento `LevelRevived` que devuelve la música del nivel en `BattleFeedback`). Al revivir se quitan las plagas en pantalla sin maíz (`_clearPests`, el mismo de `SkipWave`): en el Redmi, sin eso, las langostas que hicieron perder seguían en la puerta y se comían las 5 papas al instante.
- `AdPolicy` (`features/ads/domain`, Dart puro, `adPolicyProvider`): intersticial al salir del resultado (ganar o perder) cada N partidas, nunca si en esa partida se vio un recompensado (`_Session.watchedRewarded`). Botones: `preview-rewarded`, `battle-revive`, `settings-privacy` (solo si la ley lo pide). El maíz extra solo vale para la primera partida (al reintentar no se suma).
- Analítica: `AnalyticsService` (`NoAnalyticsService` en tests y release, `DebugAnalyticsService` en debug/profile). `BattleAnalytics` anota `level_start` (`level`, `extra_corn`), `level_complete` (`level`, `stars`, `potatoes`, `seconds`, `revived`) y `level_fail` (`level`, `wave`, `total_waves`, `seconds`, `revived`); booleanos como 0/1. Firebase queda para la Fase 11. Sin Play Games (decisión de la Fase 10).
- Público 13+ con anuncios G. Qué cambia en la política de privacidad y en Seguridad de los datos: `docs/PRIVACIDAD.md`. Cómo pasar a IDs reales y probar: `docs/MONETIZACION.md`. Tests: `FakeAdsService`, `FakeAnalyticsService`.

## Interfaz con Rive

Plan aparte, por fases (Prompt 0 + Fases 1–8): `docs/PROMPT_UI_RIVE.md`. Rehacemos toda la interfaz con Rive, con animaciones, y la conectamos al juego. Actúa también como diseñador de UX/UI de juegos móviles y animador de Rive, y explica brevemente cada decisión de Rive (artboards, componentes, layouts, view models, data binding, state machines): es mi primera vez con la herramienta.

### Contexto
- Referencias en `referencias_ui/2026-10-19/`: `propuestas/01–15` (1870×841, 20:9) son la dirección de arte; son maquetas generadas con IA (texto horneado, baja resolución, cifras ilustrativas), no assets finales. `capturas_actuales/01–13` es el juego hoy en el Redmi. `00_vista_general.jpg`, `prompts.json` (dirección de arte escrita) y `README.md`.
- Rive desktop con el MCP de Rive. Archivo de trabajo: "Guardianes UI" (la pestaña activa). Rive guarda en la nube; el juego usa el `.riv` exportado.
- Dirección visual: cartoon andino expresivo y legible, para todas las edades, horizontal. Paneles crema con borde marrón oscuro grueso y guarda tejida sutil; botones principales de maíz dorado con bisel, secundarios crema; acentos turquesa, terracota, verde hoja y ciruela; títulos en carteles de madera ocre con hojas. Letra redondeada y gruesa (¡ ¿ á é ñ). Maíz = única moneda, papas = vidas, estrellas = avance; nada de gemas, tienda, energía ni misiones.
- En Rive va la "piel" animada: botones, contadores del HUD, barra de oleadas, menús de construcción, mejora y especialización, pausa, victoria y derrota, logo y mascotas, nodos del valle, bestiario, ajustes y transiciones. Flutter sigue a cargo de navegación, toques, semántica, claves de los tests, textos traducidos y estado (Riverpod). Flame sigue dibujando el campo de batalla; el arte del mapa y los sprites de batalla no entran en este plan.

### Requisitos
1. Data binding: cada artboard expone un view model; sin inputs heredados de state machine. Estados = enums, acciones = triggers, números y textos = propiedades. Flutter escribe una propiedad solo cuando cambia.
2. Ningún texto horneado: cada texto visible es una propiedad string ligada al Text Run, llenada desde los ARB o `assets/content/i18n`. Los números los formatea Dart. Probar con el texto más largo de los dos idiomas.
3. Los toques los maneja Flutter: cada control de Rive va dentro de un widget de Flutter con la Key, la Semantics, el onTap, el sonido y la vibración, que le pasa a Rive `pressed` y `enabled`. Se conservan todas las claves existentes: `menu-play`, `menu-bestiary`, `menu-settings`, `level-<id>`, `preview-pest-<id>`, `preview-rewarded`, `preview-start`, `hud-corn`, `hud-potatoes`, `hud-wave`, `hud-next-wave`, `hud-speed`, `hud-pause`, `hud-dev`, `build-<id>`, `menu-upgrade`, `menu-branch-<id>`, `menu-sell`, `menu-targeting`, `pause-resume`, `victory-next`, `victory-unlocked`, `battle-retry`, `battle-exit`, `battle-revive`, `bestiary-pest-<id>`, `bestiary-guardian-<id>`, `settings-*` y `dev-*`. Si conviene que un toque lo detecte Rive (listener → trigger que Flutter escucha), proponerlo y justificarlo.
4. Rive no reproduce sonido: el audio sigue en `AudioService` con `SoundLimiter`. Para sincronizar un sonido con una animación, Rive dispara un trigger del view model y Flutter toca el sonido y vibra.
5. Accesibilidad: `TextScaleLimits` (HUD y menú radial hasta 1,3×, el resto hasta 2×; `text_scale_test.dart` no debe fallar), contraste AA (`app_theme_test.dart`) y una propiedad `reduceMotion` (desde `MediaQuery.disableAnimations`) que apaga bucles y movimientos grandes.
6. Responsive: artboards de pantalla a 853×384 (SafeArea de ~39 dp por la cámara), probados también a 1280×800 y 1024×768, con Layouts de Rive que reacomodan en vez de estirar.
7. Rendimiento: 60 FPS con más de 100 plagas en el Redmi (hoy 73–77 FPS en x2 con 167 plagas). Los bucles se detienen cuando no se ven. Medir el peso que agrega Rive al APK.
8. Respaldo: si el `.riv` no carga, el widget muestra el aspecto actual de Flutter.
9. Un solo archivo de Rive, exportado a `assets/rive/guardianes_ui.riv` y versionado en git. Nombres dentro del archivo (artboards, view models, propiedades, enums, state machines) en inglés con el estilo del código Dart. Un test de contrato (como `real_content_test.dart`) carga el `.riv` y comprueba que existen.
10. El contrato se documenta en `docs/UI_RIVE.md`: por artboard, su view model, cada propiedad, quién la escribe y qué animación dispara.

### Principios de animación
- Micro (presionar, cambiar un número): 80–150 ms. Entradas: 200–350 ms con ease-out o rebote leve. Paneles: 350–500 ms. Celebraciones: hasta 1,5 s, y un toque las salta al final.
- Rebote y squash & stretch sutiles: los bucles de reposo no pasan del 5 % de escala.
- En batalla la interfaz no le roba atención al mapa, salvo para avisar peligro (pocas papas, jefe).
- Ninguna animación bloquea la entrada más de 300 ms.
- Estado (habilitado/deshabilitado) y efectos (pulso, brillo) en capas separadas de la state machine.

### Cómo se trabaja con Rive
- Antes de construir una pantalla, revisar su referencia y contar en 3–5 líneas qué se va a hacer.
- Aprovechar el timeline y la state machine que trae cada artboard nuevo y ponerle nombre a todo.
- Componentes reutilizables (artboards marcados como componente) y Component Lists ligadas a listas del view model para las grillas.
- Verificar: después de cada componente, `capture_artboard` comparado con la referencia y `simulateStateMachine` con cambios de propiedades hasta alcanzar cada estado y transición.
- Scripting de Rive solo si algo no se puede con state machines, explicando por qué.
- Al cerrar cada fase: exportar el `.riv`, integrarlo en Flutter, `dart format lib test tool`, `flutter analyze`, `flutter test`, probar en el Redmi (`docs/PRUEBAS_MANUALES.md`) y mostrar capturas de Rive y del teléfono.
- El usuario usa el Redmi mientras trabajo: antes de cada toque por adb comprobar que el juego esté al frente (`adb shell dumpsys window | findstr mCurrentFocus`) y nunca abrir el juego encima de lo que tenga en pantalla sin preguntar.
- Las diferencias entre las referencias y el juego actual las decide el usuario; no se pierde ninguna función existente (doble toque para confirmar, cuenta regresiva, botón 🐞 en debug, anuncios condicionales). Las decisiones se anotan aquí abajo.

### Decisiones (UI)
Prompt 0 de UI aprobado el 2026-10-19, con todas las recomendaciones:
- Paleta muestreada de las referencias: maíz `#FDB119` (cara superior `#FEC81D`), crema de panel `#FEF3D7`, crema de botón `#FBD7A5` y de pastilla `#FDEAC5`, texto y contorno `#4A1302`, borde de panel `#AF5212`, madera `#9E430B`, guarda `#F59950`, verde éxito `#36901D` (texto `#117D16`), turquesa `#0F676F` / `#0B889F`, brillo de selección `#27D491`, terracota `#B5452A` (oscurecida desde `#CA5233` para AA con crema), ciruela `#8B2055`, estrella `#FECE18` (siempre con contorno oscuro).
- HUD: siguiente oleada abajo a la derecha con anillo de segundos y bono; papas como "N/máximo" (máximo = papas iniciales del nivel); barra de oleadas por segmentos; 🐞 solo en debug, junto a pausa.
- Construcción: los guardianes bloqueados se muestran con candado y su regla; tocarlos no construye.
- Guardián construido: tarjeta lateral (retrato, a qué ataca, estadísticas actual → siguiente, Mejorar, Objetivo, Vender) en el lado opuesto al guardián; doble toque para Mejorar y Vender; Objetivo como botón que rota con un toque. La estadística principal depende del tipo (daño; ralentización en la Llama; bono de velocidad en el Pututu).
- Especialización: ventana con dos tarjetas; primer toque = vista previa del alcance, "Elegir" confirma (`menu-branch-<id>`); la partida se pausa mientras está abierta.
- Título: escena ilustrada, Jugar grande, Bestiario y Ajustes debajo, mascotas.
- Valle: un toque abre la vista previa (como hoy), contador de estrellas "N/máximo" y aviso de bloqueo en un globo junto al nodo (no snackbar).
- Preparación: ilustración del escenario por nivel hecha en Rive en lugar de miniatura del mapa (hasta que exista el arte del mapa).
- Textos nuevos en ARB es/en ("La chacra puede esperar", "Prueba otra combinación de guardianes", "0/20").
- Victoria: hasta 2 tarjetas de desbloqueo lado a lado.
- Bestiario: grilla + ficha a la derecha; lo no descubierto como silueta "???".
- Ajustes: dos columnas, idioma como selector de tres opciones, privacidad como enlace abajo, "Desarrollo: todo desbloqueado" solo en debug.
- Botón atrás de madera arriba a la izquierda en lugar de la AppBar.
- El alcance en el mapa (Flame) pasa a círculo turquesa punteado (Fase 4).
- Nombres reales completos (dos líneas si hace falta).
- Ilustraciones: íconos, marcos, carteles, logo, fondos en capas y retratos (estilo sticker) en vectores hechos en Rive; mascotas grandes (llama y hondero) desde PNG del usuario por partes, animadas con mallas, o en vectores si no hay PNG. Retrato de prueba del Hondero en la Fase 2.
- Estructura: un widget de Rive por control tocable (Flutter lo ubica y escucha) y artboards grandes para paneles y escenas sin toques; enums `GuardianId`/`PestId` con los ids del contenido (un id nuevo cae en un retrato de respaldo). La Fase 1 confirma si el reparto aguanta el rendimiento.

### Prueba técnica (Fase 1 de UI)
- Paquete `rive` 0.14.11 (trae `rive_native` 0.1.11; la API nueva: `File.decode/asset`, `RiveWidgetController`, `DataBind.auto()`, `viewModel.string/number/boolean/trigger/enumerator`). Se importa con prefijo (`import 'package:rive/rive.dart' as rive;`) porque exporta `File`, `Fit`, etc. Muchos ejemplos de internet son de la API vieja (0.13): seguir la documentación oficial y el código del paquete en el pub cache.
- `RiveUi` (`lib/app/rive/rive_ui.dart`): ruta del `.riv`, state machine `Main`, renderer y `load()`, que devuelve `null` si falla. **Renderer: `Factory.flutter`** por decisión de la Fase 1 (`--dart-define=RIVE_RENDERER=rive` o `none` para comparar). Medido en el Redmi con estrés a x2: 6 widgets tipo HUD (2 animándose) = 114 FPS con Flutter frente a 59 con Rive (75 con `RivePanel`); línea base sin Rive 118. Sin *vector feathering* (solo existe en el renderer de Rive): brillos y sombras con degradados. `RivePanel`/textura compartida solo con el renderer de Rive (con Flutter, `RiveWidget` muestra un error; `RiveCounter` ya no la pide). En batalla, pocas animaciones a la vez y estados de reposo de un solo disparo (una state machine asentada no repinta). `main.dart` lo carga antes de `runApp` y lo pone en `riveFileProvider` (por defecto `null` → respaldo de Flutter, así corren los tests de siempre).
- `RiveCounter` (`lib/app/rive/rive_counter.dart`): primer widget envoltorio. Crea el controller en `initState` (artboard y state machine por nombre, `DataBind.auto()`), escribe `value` y dispara `gain`/`loss` en `didUpdateWidget` (no con `disableAnimations`), libera view model y controller en `dispose`, mide 34 dp de alto × escala de letra, y envuelve todo en `Semantics` con la misma etiqueta del respaldo. El maíz del HUD ya lo usa (clave `hud-corn`).
- Editor de Rive vía MCP, aprendido en la Fase 1: los `layoutStyle` de `createLayout` no aplican sus enums (alineación, `widthScaleType`): crear y luego fijar con `set_property_values` (claves de `query_property_keys`). Los textos se crean con `appendLayout` pasando `text`/`textValue`/`fontSize`/`color` y un `layoutStyle` con `widthScaleType`; para centrar uno fuera de un layout, tamaño fijo (`sizingvalue`=fixed, ancho y alto) con alineación centrada (el origen no lo mueve). El peso de Inter es el eje `wght` (`TextStyleAxis`, tag 2003265652). Las propiedades de view model creadas con valor quedan en "Initial value"/false: fijar el valor en la instancia (`propertyvalue`). Transición al terminar: `flags` = 12 (exit time en %) y `exittime` = 100. `capture_artboard` con `backgroundColor` devuelve una imagen en blanco: capturar sin fondo. `simulateStateMachine` se corta cuando la máquina se asienta: poner las entradas en cuadros cercanos.
- Fuente del `.riv` (asset de fuente: `includetypevalue` = custom, `includedunicodes`): **rangos Unicode** (`U+0020-007E,U+00A1,…`; lista completa en `docs/UI_RIVE.md`). Con los caracteres escritos tal cual el `.riv` quedó en 16 KB y el texto no se dibujaba; con todos los glifos, 890 KB; con los rangos, 199 KB (Inter variable). `rive_counter_test.dart` cuenta píxeles del texto para detectarlo.
- Peso: `librive_native.so` = 7,7 MB instalados en arm64 (~2,8 MB comprimidos, la descarga con App Bundle).
- Medir cuadros en el Redmi sin tocar el juego: `dumpsys SurfaceFlinger --latency '<hash> SurfaceView[...](BLAST)#id'` (en Android 16 el nombre sale de `--list` dentro de `RequestedLayerState{...}`, con el hash delante); `--latency-clear` antes de cada muestra.
- Tests: `rive_contract_test.dart` (artboards, state machines y propiedades del `.riv` real) y `rive_counter_test.dart`, con `File.decode` + `Factory.flutter`. Necesitan `dart run tool/setup_rive_native.dart` una vez por PC (en Windows sin Visual Studio la DLL de debug no carga, error 126, y el script copia la de release); el CI lo corre antes de `flutter test`.
- Panel de desarrollo: "Prueba de Rive" (12 contadores animados cada 250 ms, `lib/dev/rive_bench.dart`) y "en una sola textura" (`RivePanel`), para medir el costo de muchos widgets de Rive.

### Sistema visual (Fase 2 de UI)
- Artboards nuevos: `IconSet` (29 íconos, enum `IconName` ↔ `RiveIcon` en `lib/app/rive/rive_icons.dart`, mismo orden), `TitleSign` (`title`), `Panel` (layouts, sin datos), `PortraitHondero` (prueba de estilo de retratos) y `StyleGuide` (solo para revisar). Contrato y detalles en `docs/UI_RIVE.md`.
- Fuentes: Lilita One (títulos; completa en el `.riv` por su nombre reservado) y Fredoka variable (texto; recortada con rangos `U+`). Descargadas de google/fonts a `assets/fonts/` con sus `OFL.txt`, registradas en `pubspec.yaml` y en `LicenseRegistry` (`main.dart`). En Flutter, `FontWeight` elige el peso de Fredoka sin `fontVariations` (comprobado midiendo tinta).
- `AppTheme`: primario maíz con texto `#4A1302`, secundario maíz claro, terciario terracota `#B5452A`, superficie crema, barra superior de madera con Lilita One, botones con contorno oscuro (los secundarios, crema `#FBD7A5`), tarjetas con borde terracota. `GameColors`: HUD crema `#FDEAC5` con texto oscuro y `hudAccent` verde `#0E6B12` (el bono). Los nodos del valle usan `onPrimary` y contorno oscuro.
- Editor de Rive vía MCP (Fase 2): el MCP no sube `.ttf` (las fuentes se agregan desde el selector del editor, catálogo de Google Fonts, y luego `fontassetid`). Al crear formas, `thickness` de las pinturas se ignora (queda 1): fijar `thickness` (47), `cap` (48) y `join` (49) del Stroke después. Los trazos de `createShapes` quedan cerrados: `isclosed` (32) = false para líneas y arcos. Al crear textos se ignoran `color` y `fontSize`: fijar el color en el SolidColor (estilo + 2), el tamaño en el estilo (274) y el peso en el eje `wght` (estilo + 4). En `layoutStyle` funcionan `fixed`/`fill`/`hug`, `center`, `topLeft`, `wrap`, `row`/`column`; las posiciones absolutas necesitan además las unidades en `point` (621–624). Un texto hijo directo de un artboard lo coloca el layout: envolverlo en un grupo para moverlo libre. Las pinturas de un texto no se reordenan: para dejar el contorno debajo, agregar de nuevo el relleno y borrar el viejo. `group_editor` ignora `x`/`y`: fijarlos después (13/14). Los objetos nuevos se dibujan encima (el primer hijo es el de adelante). `capture_artboard` no aplica el data binding: para ver estados, exportar y renderizar con un test temporal (`RiveWidget` + `RepaintBoundary.toImage`). `export_file` no sobrescribe: borrar el archivo antes. Un valor de enum que no existe no se aplica (queda el anterior).
- El editor creó solos view models vacíos (`ViewModel1/2/3`) sin artboard: se borraron.

### Kit de componentes (Fase 3 de UI)
- Artboards: `PrimaryButton`, `SecondaryButton` y `RoundButton` (view model `Button` compartido), `Counter` ampliado (104 × 60: `icon`, `delta` "+N" que flota, `danger` con pulso), `WaveBar` (barra continua, no segmentos: hasta 15 oleadas), `Star`, `Toggle`, `Segmented`, `Tab`, `Tooltip`, `Badge`, `Panel` con entrada y salida, y `Catalog` (todos los estados, una instancia de view model por estado). Todos con `reduceMotion` cuando tienen bucles. Contrato en `docs/UI_RIVE.md`.
- Flutter: `RiveBinding` + `RiveBindingState` (`lib/app/rive/rive_binding.dart`) son la base de cada envoltorio: binding por nombre, `RiveContractException` si falta una propiedad (→ respaldo del tema), `reduceMotion` desde `MediaQuery`. Envoltorios: `RiveButton` (`.round`; ancho medido con `TextPainter`, `Fit.layout` + `layoutScaleFactor` = escala de letra; `onDenied` para "no alcanza"), `RiveCounter`, `RiveWaveBar`, `RiveStar`, `RiveToggle`, `RiveSegmented`, `RiveTab`, `RiveTooltip`, `RiveBadge`, `RivePanel`. Los toques los maneja Flutter (`GestureDetector` + `Semantics`; Rive con `RiveHitTestBehavior.none`). `UiFeedback` toca `Sfx.uiTap`/`uiDeny` y vibra `Haptic.tap`/`deny` según Ajustes.
- Ya en uso: botones del título, la preparación y los overlays de la partida (con sus claves de siempre). El resto llega con su fase. Panel 🐞 → "Catálogo de la interfaz" (`lib/dev/ui_catalog_screen.dart`) para probarlo todo en el teléfono.
- Rive no anima los layouts (animación de layout del estilo) cuando el valor llega por data binding: el número se anima desde Flutter con `RiveNumberTween` (selector y barra de oleadas). Lo vimos en el Redmi, no en los tests ni en el editor. La letra recortada no trae el signo menos tipográfico (U+2212): usar el guion ASCII o sumarlo al recorte.
- Cada `DataBind.auto()` crea instancias propias, también las anidadas (dos botones no comparten el ícono). Una instancia de view model guardada en el archivo solo se puede enlazar a un componente: en el `Catalog`, dos barras con la misma instancia de bandera dejaban a la segunda sin ícono.
- Editor de Rive vía MCP (Fase 3): en el MCP la opacidad y la escala van en porcentaje (100 = normal); los layouts de `appendLayout` nacen con opacidad 1 (= 1 %): fijar 18 = 100. `createLayout`/`appendLayout` suelen no aplicar `width`/`height`/`alignment`: fijar `layoutwidthscaletype` (655) y `layoutheightscaletype` (656) en el estilo, unidades 607/608 = point, ancho y alto en el componente (7/8) y la alineación (632). Los textos de `layout_editor` fallan sin `text`/`textValue`/`content`/`value` ("type 'Null' is not a subtype of type 'String'") y nacen mal: participante en fill (655/656 = 2, hug), overflow 287 = 5 (poner 0) y origen 0 (poner 366/367 = 0.5, alineación 281 = 0); duplicar un texto que ya funciona es más rápido. Las formas dentro de un layout toman el tamaño del layout: van dentro de un grupo. `group_editor` crea el grupo desplazado (−x/−y del padre): fijar 13/14 después. Un texto dentro de un grupo no respeta el origen: tamaño fijo (284 = 2, 285/286), alineación centrada y x/y a mano. Un layout dentro de un grupo se ve bien en el editor pero sale corrido en el runtime: no hacerlo. Los artboards nuevos traen un relleno oscuro (id + 1): borrarlo. `createStateMachineLayers` no une `Entry` con el primer estado: agregar esa transición. Los comandos de animación actúan sobre el artboard seleccionado (`select_objects` antes). Para cambiar el valor de un keyframe que ya existe: `set_property_values` con 70 (double) sobre el id del keyframe. Duración de una animación en cuadros: 57 (a 60 fps); bucle: 59 = 1. `simulateStateMachine` deja de leer entradas cuando la máquina se asienta. Instancias: `createViewModelInstances` copia la de por defecto; la referencia de una propiedad de tipo view model es 577 (id de la instancia) y los números, 575. Llamadas en paralelo justo después de crear objetos pueden no verlos ("not found"): esperar el resultado. `listDataBinds` lista todo el archivo. La exportación solo incluye artboards marcados como componente (792) y trae también `Watermark`/`NuRive*` (del plan de Rive, no se dibujan).

### HUD y menús de batalla (Fase 4 de UI)
- Artboards nuevos: los retratos de los cinco guardianes y uno de respaldo, `Portrait` (enum `GuardianId`, el primero `unknown` es el respaldo), `SpeedButton`, `NextWave` (anillo con *trim path*), `Banner` (cartel "Oleada N" y aviso del jefe), `BuildOption`, `GuardianInfo` y `BranchCard`; `SecondaryButton` ganó la capa `Danger` y `Tooltip` la propiedad `arrow`. Contrato en `docs/UI_RIVE.md`.
- Flutter: envoltorios `RivePortrait`, `RiveSpeedButton`, `RiveNextWaveButton`, `RiveWaveBanner`, `RiveBuildOption`, `RiveGuardianInfo`, `RiveBranchCard` y `RiveTitleSign`; `RiveCounter(max:)` con ancho medido; `RiveButton(danger:)`. En la partida: `BattleHud` + `BattleNextWave` (abajo a la derecha) + `BattleWaveBanner`, `BuildMenu` en abanico (bloqueados con candado y su regla), `GuardianCard` (ficha lateral) y `SpecializationWindow` (pausa la simulación con `clock.paused`, Flame sigue dibujando el alcance). El alcance es un círculo turquesa punteado.
- Editor de Rive vía MCP (Fase 4): `createStateMachine` y `createLinearAnimations` toman la duración en **segundos** (24 = 1440 cuadros): fijar 57 en cuadros después. Duplicar un artboard copia las formas pero no las animaciones; puede dejar una state machine vacía llamada `Main` (borrarla: el runtime elige por nombre) y cambiar el orden de los hijos (el bisel quedó delante de la cara: `sendToBack`). Un texto con `LayoutParticipant` dentro de un grupo se acomoda en el layout del artboard (dos textos en el mismo grupo se pusieron en fila y uno se salió del artboard): para textos con x/y a mano, borrar su `LayoutParticipant`. `group_editor` ignora x/y al crear un grupo vacío: fijarlos después. `capture_artboard` con `backgroundColor` devuelve una imagen en blanco: capturar sin fondo. Varios componentes anidados del mismo view model en un artboard (tres `IconSet`) comparten la instancia por defecto: crear una instancia para cada uno y apuntarla con 577. El final del *trim path* (115) se enlaza con el valor crudo 0–1 (sin el conversor de porcentaje). Transiciones: duración de mezcla en ms con 158. Un estado de una capa con animación sin claves deja mandar a las capas de abajo (así la capa `Danger` del botón secundario no pisa el gris de deshabilitado).
- Flutter: `Curve.transform` devuelve 0 en t = 0 sin llamar a la curva (`Threshold(0)` no sirve para "aparecer de una vez" en un `AnimatedSwitcher`): `BattleNextWave` guarda el último botón y lo desvanece sin moverlo del árbol, así el rebote de Rive sigue. En los ARB ya existían `statRange` y compañía (Bestiario): las etiquetas de la ficha son `cardDamage`, `cardSlow`, `cardBoost`, `cardRange` y `cardNextWord`.

### Pausa, victoria y derrota (Fase 5 de UI)
- Decisiones del usuario (2026-10-20, todas las recomendadas): la llama hecha en vectores en Rive, de cuerpo entero, con cara feliz y triste, parpadeo y salto; la pausa sin X; los títulos de la referencia ("¡Cosecha a salvo!" / "La collca se quedó sin papas"; en inglés "Harvest saved!" / "The collca ran out of potatoes"); en la tarjeta de desbloqueo, el guardián con su retrato y el nivel con el ícono de bandera hasta la ilustración de la Fase 6.
- Ajustes al mirar las referencias 10–12: la tarjeta de desbloqueo es horizontal (280 × 96) y el cartel de derrota conserva las mazorcas (sin sol y con la madera algo apagada). La victoria pone la llama a la izquierda tapando el borde del panel, como la referencia.
- Artboards nuevos: `Llama`, `SceneSign` (enum `SceneVariant`), `StatPill`, `UnlockCard`, `CornRain` y `Collca`. Contrato en `docs/UI_RIVE.md`.
- Flutter: `RiveSceneSign`, `RiveLlama`, `RiveStatPill`, `RiveUnlockCard`, `RiveCornRain`, `RiveCollca`; `RiveBinding.widget(alignment:)`; `Sfx.star` + `Haptic.star` (`UiFeedback.star()`, WAV de `tool/generate_placeholder_audio.py`). Overlays reescritos en `battle_overlays.dart`: `VictoryTimeline` marca la coreografía (estrellas cada 380 ms desde los 520, conteo de 700 ms, desbloqueos, lluvia y salto al final); un toque fuera de los botones salta al final sin más sonidos; con menos movimiento se ve el final directo y sin sonidos de estrella; los botones responden desde los 280 ms. Las escenas se achican enteras con `FittedBox(scaleDown)` en vez de desplazarse. La lluvia son dos `RiveCornRain` (una espejada): una sola a todo el ancho deja los granos enormes. `DefeatOverlay` ahora pide `potatoes` y `maxPotatoes`; `VictoryOverlay`, `maxPotatoes` y `List<UnlockedItem>`. ARB: fuera `victoryPotatoes`/`victoryCorn`/`victoryUnlocked`; nuevas `pauseSubtitle`, `resultPotatoes`, `resultCorn`, `unlockedLabel` y `defeatHint`.
- Editor de Rive vía MCP (Fase 5): `open_file_editor createArtboard` crea la state machine "State Machine 1" (renombrarla a `Main` con `rename_objects`, que también renombra animaciones) y el relleno oscuro de siempre. `bindViewModelToComponent` solo encuentra el view model del artboard activo (seleccionar antes un objeto de ese artboard); `databindpathids` (582) no se escribe a mano. Un enum de una instancia nueva queda sin valor (`propertyvalue` 560 = "0-0"): fijarlo con el id del valor; en las condiciones se puede pasar la clave ("pause") y el MCP la convierte en id. `simulateStateMachine` no mueve enums. `duplicate_objects` ignora ids repetidos (duplicar en tandas que se duplican). Las transiciones se borran con `delete_objects`. En `createShapes`, varios `moveTo` en un mismo path se unen con líneas: un path por segmento. Un estado de un solo disparo sin salida se queda en su último cuadro. Los objetos creados con `createShapes` quedan uno delante del otro en orden inverso al de la lista (el primero, atrás).
- Flutter y tests: un `Semantics` con solo `label` dentro de una fila puede fundirse con el de arriba y `find.bySemanticsLabel` no lo encuentra: `container: true`. El contenido de `RivePanel` aparece en 130 ms y antes no tiene semántica. En los tests la letra es la de prueba (cuadrados) y `RiveButton.widthFor` mide de más: `rive_scenes_test.dart` carga Fredoka y Lilita One con `FontLoader`. Un `Ticker` que arranca durante un cuadro toma la hora de ese cuadro (los tiempos de la coreografía se prueban exactos).

### Título, valle y preparación (Fase 6 de UI)
- Decisiones del usuario (2026-10-20, todas las recomendadas): en el valle un toque abre la vista previa como hoy (la barra de abajo es un atajo al nivel sugerido, con anillo); las plagas de la preparación van en una fila que se desliza (se ven 5 y asoma la sexta); el hondero de cuerpo entero en vectores en Rive; la fase se entrega en tres partes (título, valle, preparación) con commit, prueba en el Redmi y revisión en cada una.
- Parte A (título): artboards `Valley` (paisaje en capas, también fondo del mapa), `Logo`, `Hondero` (con la cabeza del retrato) y `GorgojoPeek`; `Llama.chewing` y `Collca.full`. Contrato en `docs/UI_RIVE.md`. Flutter: `RiveValley`, `RiveLogo`, `RiveHondero`, `RiveGorgojoPeek` y `RiveLlama(chewing:)`; ARB `logoLine1/2/3` (en: "GUARDIANS" / "OF THE" / "CHACRA"). El logo cae por líneas, no letra por letra (el MCP no crea modificadores de texto). Jugar respira desde Flutter solo con Rive cargado: sin archivo el título queda quieto y `pumpAndSettle` sigue funcionando.
- Editor de Rive vía MCP (Fase 6): `createShapes` sigue ignorando el grosor de los trazos y cerrando los caminos abiertos (fijar 47 y 32 después, como en la Fase 2). `animation_editor` trabaja sobre el artboard seleccionado, no sobre el enfocado: si `getSelectedArtboard` devuelve otro con `isSelected` true, `select_objects([])` y luego `focusArtboard`. `addProperties` devuelve todos los view models del archivo (respuesta enorme): crear el view model con todas sus propiedades de una vez. Una instancia de un view model anidado se elige con 577 en la propiedad de la instancia del padre y `bindViewModelToComponent` (así la collca del valle está llena). Tras `sendToBack`, `bringForward` necesita un paso más del esperado.
- Rendimiento del título (Redmi, profile): 90 FPS con todo animándose; el límite es el raster (10,7 ms por cuadro: el valle a pantalla completa se rasteriza entero en cada cuadro con Impeller), no la UI (5,4 ms). Un `RepaintBoundary` por widget de Rive no cambió nada y no se dejó. Si el mapa (parte B) necesitara margen: capas quietas del valle dibujadas una vez a imagen. Detalle en `docs/UI_RIVE.md` ("Mediciones de la Fase 6").

## Reglas de trabajo
- Trabajamos UNA fase a la vez. Al terminar una fase: resume qué hiciste, cómo probarlo y espera mi confirmación antes de seguir.
- Antes de escribir código en cada fase, muéstrame un plan breve con los archivos que vas a crear o modificar.
- Prioriza tener un nivel jugable de principio a fin antes de agregar mucho contenido.
- Los valores de balance (vida, daño, costos, velocidades) van siempre en los JSON, nunca en el código.
- Usa versiones estables y actuales de los paquetes; verifícalas en pub.dev en lugar de asumirlas de memoria.
- Ejecuta `flutter analyze` y `flutter test` al final de cada fase y corrige los errores.
- Explica brevemente las decisiones importantes de arquitectura: quiero aprender, no solo copiar.
- Prefiere soluciones simples. No agregues funcionalidades que no pedí; si crees que falta algo, propónlo al final de la fase.
- Al cerrar cada fase, haz un commit de git con un mensaje en formato Conventional Commits.

## Comandos útiles
```powershell
dart format lib test tool
flutter analyze
flutter test
dart run tool/balance.dart
dart run tool/stress.dart
flutter run --profile
flutter run -d chrome
flutter build web
```
