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
│  │  ├─ guardians/   un JSON por guardián (estadísticas, costo, comportamientos, mejoras y ramas)
│  │  ├─ pests/       un JSON por plaga
│  │  ├─ levels/      una carpeta por nivel: level.json (oleadas, maíz y papas iniciales) + map.tmx
│  │  └─ i18n/        es.json, en.json: nombres y fichas del bestiario, buscados por id
│  └─ tilesets/       tileset de placeholder (.png + .tsx)
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
│     ├─ settings/    domain · data · presentation
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
flutter analyze
flutter test
flutter run -d chrome
flutter build web
```
