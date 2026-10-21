# La interfaz en Rive

La interfaz del juego se dibuja y anima con [Rive](https://rive.app). El plan por fases está en [PROMPT_UI_RIVE.md](PROMPT_UI_RIVE.md) y las decisiones, en la sección "Interfaz con Rive" de [CLAUDE.md](../CLAUDE.md). Este documento es el **contrato** entre el archivo de Rive y el código, y guarda lo que se midió.

## Cómo funciona

- **Un solo archivo**, "Guardianes UI" en el editor de Rive (vive en la nube de Rive). El juego usa su exportación para runtime: `assets/rive/guardianes_ui.riv`, versionada en git.
- **Flutter manda y Rive dibuja.** Cada pieza de Rive va dentro de un widget de Flutter que tiene la `Key` de los tests, la `Semantics` para TalkBack, los toques, el sonido y la vibración. El widget le escribe datos a Rive (el número, si está presionado) y Rive decide cómo se ve y cómo se anima.
- **Data binding.** Cada artboard tiene un *view model* (sus datos) y una state machine llamada `Main` que reacciona a esos datos. No se usan los *inputs* viejos de las state machines.
- **Respaldo.** `main.dart` carga el archivo antes del primer cuadro (`RiveUi.load`). Si no se puede (faltan las librerías nativas, el archivo está roto), `riveFileProvider` queda en `null` y cada widget muestra su aspecto de Flutter. Así también corren los tests que no prueban Rive.

### Vocabulario de Rive

| Rive | Qué es | En Flutter se parece a |
|---|---|---|
| Artboard | Un lienzo con su contenido: un botón, un panel, una pantalla | Un widget |
| Componente | Un artboard reutilizable dentro de otro | Un widget dentro de otro |
| Layout | Cajas flex dentro del artboard (fila, columna, relleno, separación) | `Row`, `Column`, `Padding` |
| Timeline | Una animación con keyframes | Un `AnimationController` con su `Tween` |
| State machine | Estados (cada uno con su timeline) y transiciones con condiciones | Una máquina de estados escrita a mano |
| View model | Los datos del artboard: textos, números, booleanos, enums y triggers | El estado de un widget |
| Data bind | "Este texto muestra la propiedad `value`" | Pasarle un parámetro a un widget |
| Trigger | Una propiedad que no guarda un valor: solo "dispara" | Llamar a un método (`animar()`) |

## El contrato

Los nombres van en inglés, como el código, porque Dart los busca como texto. `test/app/rive/rive_contract_test.dart` carga el `.riv` real y falla si falta algo.

### `Counter` (Fases 1 y 3)

Pastilla del HUD con ícono y número. 104 × 60: la pastilla ocupa los 35 de arriba y el "+N" flota en el resto, por debajo, sin empujar lo que haya alrededor (el widget mide solo la pastilla y deja que el dibujo se salga hacia abajo). Widget: `RiveCounter` (`lib/app/rive/rive_counter.dart`), en el HUD: maíz (clave `hud-corn`) y papas con máximo (clave `hud-potatoes`, Fase 4).

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `value` | string | `RiveCounter`, con el número formateado por Dart | El texto del número |
| `icon` | view model `IconSet` | `RiveCounter` (`icon`, por defecto `corn`) | El ícono de la pastilla |
| `gain` | trigger | `RiveCounter`, cuando el número sube | El ícono rebota (escala 135 %, rebote elástico), el número destella en verde `#117D16` (0,4 s) y flota `delta` (0,9 s) |
| `delta` | string | `RiveCounter`, antes de `gain` ("+25") | La etiqueta verde que sube y se desvanece |
| `loss` | trigger | `RiveCounter`, cuando el número baja | El número y el borde destellan en rojo `#C43403` y el ícono tiembla: 0,4 s |
| `danger` | boolean | `RiveCounter` (`danger`; pocas papas en la Fase 4) | Un anillo rojo late sobre la pastilla (1 s, en bucle) |
| `reduceMotion` | boolean | `RiveBindingState`, desde `MediaQuery.disableAnimations` | El aviso de peligro queda fijo, sin latir |

State machine `Main`, tres capas: `Layer 1` (`Idle` ← cualquier estado → `Gain` o `Loss` con su trigger → vuelven a `Idle`), `Delta` (`DeltaHidden` → `DeltaFloat` con `gain` → vuelve al terminar) y `Danger` (`Calm`, `Pulse` y `Steady`). Con "quitar animaciones" del teléfono solo cambia el número.

### `PrimaryButton`, `SecondaryButton` y `RoundButton` (Fase 3)

Los botones del juego. Los tres comparten el view model `Button`. Widget: `RiveButton` (`lib/app/rive/rive_button.dart`); `RiveButton.round` para el redondo.

- `PrimaryButton`: maíz con degradado y bisel, 200 × 56 de diseño. Un brillo lo cruza cada ~4 s.
- `SecondaryButton`: crema `#FBD7A5`, sin brillo.
- `RoundButton`: 56 × 56, solo con ícono (pausa, velocidad, atrás, cerrar). Con `danger`, la cara pasa a roja.

Los de texto se estiran con `Fit.layout`: Flutter mide el texto con la misma letra (Fredoka 20, peso 700) y le pasa el ancho (`RiveButton.widthFor`, mínimo 140); con letra grande, todo crece con `layoutScaleFactor`.

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `label` | string | `RiveButton`, desde los ARB | El texto (el redondo no lo muestra: es su tooltip y lo que lee TalkBack) |
| `icon` | view model `IconSet` | `RiveButton` | El ícono a la izquierda del texto |
| `hasIcon` | boolean | `RiveButton` | Sin ícono, su lugar desaparece (`display` ligado con el convertidor `HiddenUnless`) |
| `pressed` | boolean | `RiveButton`, al apoyar y levantar el dedo | Se hunde: escala 0,94 y bisel bajo en ~80 ms; al soltar, rebote (0,3 s) |
| `enabled` | boolean | `RiveButton` (`onPressed` no nulo) | Apagado: grises y no reacciona a `pressed` |
| `deny` | trigger | `RiveButton`, al tocarlo deshabilitado si tiene `onDenied` | "No se puede" (no alcanza el maíz): una sacudida corta de 0,3 s |
| `danger` | boolean | `RiveButton.round` | Cara roja (opacidad de `RedFace` ligada con `BoolToNumber`) |
| `reduceMotion` | boolean | `RiveBindingState` | Apaga el brillo del principal |

State machine `Main`: capa `Layer 1` con `Idle`, `Pressed`, `Release`, `Disabled` y `Deny`; el principal tiene además la capa `Shine` (`ShineLoop` y `ShineOff`), separada para que el brillo no se mezcle con el estado.

### `IconSet` (Fase 2)

Los 29 íconos de la interfaz en un solo artboard de 48 × 48, todos con el mismo estilo: contorno `#4A1302` de 2,2 dp con puntas redondeadas y los colores de la paleta. Dart: `RiveIcon` (`lib/app/rive/rive_icons.dart`).

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `icon` | enum `IconName` | El componente que lo usa, con un valor de `RiveIcon` (su `name`) | Muestra ese ícono |

Valores, en este orden: `corn`, `potato`, `star`, `starEmpty`, `play`, `pause`, `fastForward`, `nextWave`, `gear`, `book`, `home`, `retry`, `back`, `close`, `lock`, `upgrade`, `sell`, `target`, `ground`, `air`, `music`, `sound`, `vibration`, `language`, `ad`, `check`, `flag`, `shield`, `damage`.

Cómo está hecho: cada ícono es un grupo (`icon_<nombre>`) cuya opacidad se liga a `icon` con un convertidor de grupo: `EnumToIndex` (enum → número) y una fórmula `max(0, 1 - pow({Input} - k, 2))`, que da 1 solo cuando el índice es `k`. **El orden importa**: un ícono nuevo va al final del enum (y de `RiveIcon`), con su grupo y su convertidor `IsIconNN`. Un valor que no está en el enum no se aplica y queda el que había (el primero, `corn`). `rive_contract_test.dart` compara el enum con `RiveIcon`, y `rive_icons_test.dart` dibuja los 29 y comprueba que cada uno pinte algo.

### `TitleSign` (Fase 2)

Cartel de madera para los títulos: tabla con degradado, vetas, borde claro interior y hojas a los lados. 360 × 96. El título va en Lilita One crema con contorno oscuro de 5 dp y se achica solo si no cabe (*fit font size*).

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `title` | string | La pantalla, desde los ARB | El texto del cartel |

### `Panel` (Fases 2 y 3)

Marco de los paneles y tarjetas: borde terracota `#AF5212` con contorno oscuro, interior crema, guarda naranja `#F59950` y un rombo tejido en cada esquina. Hecho con layouts, así que se estira a cualquier tamaño (`Fit.layout`). El contenido lo pone Flutter encima. Widget: `RivePanel` (`lib/app/rive/rive_panel.dart`), que mueve el contenido junto con el marco.

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `visible` | boolean | `RivePanel` | `true`: el marco cae 40 dp con rebote y aparece (0,42 s). `false`: baja 24 dp y se desvanece (0,2 s) |
| `reduceMotion` | boolean | `RiveBindingState` | Entra solo desvaneciéndose (`EnterCalm`, 0,15 s) |

State machine `Main`: `Hidden`, `Enter`, `EnterCalm`, `Shown` y `Exit`. Los overlays (pausa, victoria, derrota) lo usarán en la Fase 5.

### `PortraitHondero` (Fase 2, prueba de estilo)

Retrato *sticker* del Hondero, 120 × 120: chullo rojo con guarda en zigzag y pompón, orejeras con borlas, poncho con franjas turquesa y amarilla. Es la prueba de estilo de los retratos; en las fases siguientes se hacen los otros guardianes y las plagas, y se juntan en un `Portrait` con un enum (como `IconSet`).

### `StyleGuide` (Fase 2, solo para revisar)

La guía de estilo en el editor: los 19 colores con su uso, el contraste de cada combinación de texto, las dos fuentes y una fila con las formas base (panel, cartel, botones dorado y crema, retrato). No va en el `.riv`: la exportación solo incluye los artboards marcados como componente (el `Catalog` lo está para poder dibujarlo en los tests y en el teléfono). La exportación también trae tres artboards de Rive (`Watermark`, `NuRiveBrandmark01`, `NuRiveWordmark01`), por el plan de la cuenta: el juego no los dibuja.

### `WaveBar` (Fase 3)

"Oleada 3/10" con una bandera y una barra que se llena. 200 × 44 de diseño, `Fit.layout`. Widget: `RiveWaveBar` (`lib/app/rive/rive_wave_bar.dart`); el HUD la usa en la Fase 4. Es una barra continua y no por segmentos: los niveles tienen hasta 15 oleadas y los segmentos quedarían muy finos en un teléfono.

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `label` | string | `RiveWaveBar`, desde los ARB | El texto |
| `progress` | number (0–1) | `RiveWaveBar` (oleada / total), paso a paso durante 0,45 s | El ancho del relleno (`ProgressToPercent`) |
| `boss` | boolean | `RiveWaveBar` | La barra pasa a terracota y aparece un círculo ciruela con "!" que late (0,8 s, en bucle) |
| `waveStarted` | trigger | `RiveWaveBar`, al subir la oleada | El texto rebota y la pastilla destella (0,5 s) |
| `icon` | view model `IconSet` | `RiveWaveBar` (siempre `flag`) | El ícono |
| `reduceMotion` | boolean | `RiveBindingState` | El aviso del jefe queda fijo |

State machine `Main`: `Layer 1` (`Idle`, `WaveStart`) y `Boss` (`Normal`, `BossAlert`, `BossSteady`).

### `Star` (Fase 3)

Estrella de puntuación, 56 × 56: vacía `#E7D9BD` con contorno `#8A6A4A`; llena `#FECE18` con contorno oscuro. Widget: `RiveStar` (`lib/app/rive/rive_star.dart`); la victoria la usa en la Fase 5 (quien cambia `filled` toca el sonido de cada estrella).

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `filled` | boolean | `RiveStar` | `true`: la estrella llena crece girando hasta 125 % y se asienta, con un anillo que se abre y seis chispas (0,6 s). `false`: se encoge (0,15 s) |
| `reduceMotion` | boolean | `RiveBindingState` | Se llena de golpe, sin estallido |

State machine `Main`: `Empty`, `Fill`, `Filled` y `Unfill`.

### `Toggle` (Fase 3)

Interruptor, 68 × 40: riel gris `#D8DBCF` (apagado) o verde `#36901D` (encendido) y perilla crema. Widget: `RiveToggle` (`lib/app/rive/rive_toggle.dart`), con Semantics de interruptor; Ajustes lo usará en la Fase 7.

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `on` | boolean | `RiveToggle` | La perilla cruza con squash (128 % × 82 %) y rebote, y el riel cambia de color (0,25 s) |
| `enabled` | boolean | `RiveToggle` (`onChanged` no nulo) | Apagado: 45 % de opacidad |
| `reduceMotion` | boolean | `RiveBindingState` | Sin uso todavía (el movimiento es corto) |

State machine `Main`: `Layer 1` (`Off`, `TurnOn`, `On`, `TurnOff`) y `Enabled` (`Enabled`, `Disabled`).

### `Segmented` (Fase 3)

Tres opciones con una pastilla de maíz que se desliza hasta la elegida (Sistema / Español / English). 300 × 44 de diseño, `Fit.layout`. Widget: `RiveSegmented` (`lib/app/rive/rive_segmented.dart`): Flutter pone tres zonas tocables, cada una con su Semantics y su Key (`optionKeys`).

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `label0`, `label1`, `label2` | string | `RiveSegmented`, desde los ARB | Los textos |
| `selected` | number (0–2) | `RiveSegmented`, paso a paso durante 0,25 s | La posición de la pastilla (`positionLeft` en %, con el convertidor `ThirdToPercent`) |

No tiene animaciones propias: el deslizamiento lo hace Flutter (ver `RiveNumberTween` más abajo).

### `Tab` (Fase 3)

Pestaña con esquinas de arriba redondeadas, 140 × 46 de diseño, `Fit.layout` (Flutter mide el texto: Fredoka 15, peso 700). Widget: `RiveTab` (`lib/app/rive/rive_tab.dart`); el bestiario la usará en la Fase 7.

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `label` | string | `RiveTab`, desde los ARB | El texto |
| `selected` | boolean | `RiveTab` | Sube 6 dp con rebote y pasa de crema a maíz (0,25 s) |
| `icon`, `hasIcon` | view model `IconSet`, boolean | `RiveTab` | El ícono opcional |

State machine `Main`: `Unselected`, `Select`, `Selected` y `Deselect`.

### `Tooltip` (Fase 3)

Globo crema con borde terracota y flecha abajo. 220 × 64 de diseño, `Fit.layout`: Flutter mide el texto (Fredoka 14, peso 600, en varias líneas si hace falta) y le da el tamaño (`RiveTooltip.sizeFor`). Widget: `RiveTooltip` (`lib/app/rive/rive_tooltip.dart`), que no tapa toques y TalkBack anuncia al aparecer. Sin flecha (`arrow`) es la etiqueta de abajo de los menús de la partida (Fase 4).

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `text` | string | `RiveTooltip`, desde los ARB | El texto |
| `visible` | boolean | `RiveTooltip` | Aparece subiendo 6 dp (0,22 s) y se va bajando y desvaneciéndose (0,15 s) |
| `arrow` | boolean | `RiveTooltip` (`arrow`, por defecto `true`) | Sin flecha, una etiqueta (Fase 4) |
| `reduceMotion` | boolean | `RiveBindingState` | Sin uso todavía |

State machine `Main`: `Hidden`, `Show`, `Shown` y `Hide`.

### `Badge` (Fase 3)

Etiqueta ciruela `#8B2055` con texto crema, 84 × 32. Widget: `RiveBadge` (`lib/app/rive/rive_badge.dart`); la preparación del nivel la usará en la Fase 6.

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `label` | string | `RiveBadge`, desde los ARB ("¡Nuevo!") | El texto (centrado en una caja fija: "New!" también cabe) |
| `reduceMotion` | boolean | `RiveBindingState` | Quieta (`Still`) en vez de menearse |

State machine `Main`: `Wiggle` (3 s en bucle: quieta 2 s, después se menea ±8° y crece 10 %) y `Still`.

### `Catalog` (Fase 3, para revisar)

Todos los componentes en todos sus estados, 1000 × 640: botones (normal, presionado, deshabilitado, secundario, redondo, redondo en peligro), contadores (maíz y papas en peligro), barras de oleadas (normal y jefe), estrellas, interruptores (apagado, encendido, deshabilitado), la etiqueta, el selector, las pestañas, el tooltip y el panel. Su view model `Catalog` tiene una propiedad por componente que apunta a una instancia con los datos de ese estado (`PrimaryPressed`, `WaveBoss`, `IcoFlagBoss`…). Una instancia anidada solo puede estar en un lugar a la vez: cada uno tiene la suya, también los íconos.

`MCP capture_artboard` lo muestra sin datos (los textos de diseño); con datos lo dibuja `test/app/rive/rive_catalog_test.dart`, que busca el color de cada estado y guarda la imagen con `--dart-define=CATALOG_PNG=build/catalog.png`. En el teléfono está en el panel de desarrollo (🐞 → "Catálogo de la interfaz"), con cada componente para tocarlo debajo.

### `Portrait` y los retratos (Fase 4)

Un artboard por guardián, 120 × 120, en el estilo de `PortraitHondero` (plano, contorno `#4A1302` de 2,4, fondo transparente): `PortraitHondero`, `PortraitLlama` (llama crema con borlas y manta a rayas), `PortraitTullpa` (fogón de piedra con llama), `PortraitCondor` (alas abiertas con banda blanca, gorguera, cabeza roja y pico marfil), `PortraitPututu` (caracola con cordón tejido, borlas y ondas de sonido) y `PortraitUnknown` (silueta con "?", el respaldo).

`Portrait` los anida a los seis en un grupo y muestra uno: cada componente tiene la opacidad enlazada a `guardian` con los conversores `IsIcon00`…`IsIcon05` (los mismos del `IconSet`). Widget: `RivePortrait` (`lib/app/rive/rive_portrait.dart`); también va anidado en `BuildOption`, `GuardianInfo` y `BranchCard`.

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `guardian` | enum `GuardianId` | `RivePortrait` / los envoltorios que lo anidan | `unknown`, `hondero`, `llama`, `tullpa`, `condor` o `pututu` |

El primer valor es el respaldo: un id que el enum no tiene (un guardián nuevo en los datos) deja el primero, y `PortraitRive.valueFor` ya lo cambia por `unknown`. Para sumar un guardián: dibujar su artboard, anidarlo en `Portrait`, agregar el valor al final del enum, enlazar su opacidad con `IsIconNN` y sumar el id a `PortraitRive.ids` (el test de contrato compara las dos listas).

### `SpeedButton` (Fase 4)

El botón redondo de velocidad del HUD, 56 × 56 (copia de `RoundButton` con su propio view model). Widget: `RiveSpeedButton` (`lib/app/rive/rive_speed_button.dart`), clave `hud-speed`.

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `label` | string | `RiveSpeedButton` | "x1" o "x2" |
| `fast` | boolean | `RiveSpeedButton` | Cara de maíz `#F2B33D` (enlazada) y, al cambiar, la cara da una vuelta con un pequeño rebote (0,4 s); en x2 dos flechitas avanzan y se apagan por turnos (0,8 s en bucle) |
| `pressed` | boolean | `RiveSpeedButton` | Se hunde como los demás botones |
| `enabled`, `deny` | boolean, trigger | — | Están, sin uso: el botón siempre se puede tocar |
| `reduceMotion` | boolean | `RiveBindingState` | Sin vuelta y con las flechas quietas |

State machine `Main`, dos capas: `Press` (`Idle`, `Pressed`, `Release`) y `Speed` (`Slow`, `SpinUp`, `FastLoop`, `FastStill`, `SpinDown`). La entrada elige el estado según `fast`: al volver de la pausa el HUD se vuelve a montar y no hace la vuelta otra vez.

### `NextWave` (Fase 4)

"Siguiente oleada", abajo a la derecha: pastilla crema (copia de `SecondaryButton`) con un anillo de cuenta regresiva alrededor del ícono, los segundos y el bono en verde `#2F7A18`. `Fit.layout`, ancho medido por `RiveNextWaveButton.widthFor`. Widget: `RiveNextWaveButton` (`lib/app/rive/rive_next_wave.dart`), clave `hud-next-wave`.

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `label` | string | `RiveNextWaveButton` | "12 s" |
| `bonus` | string | `RiveNextWaveButton`, desde los ARB | "+18" |
| `progress` | number | `RiveNextWaveButton`, con `RiveNumberTween` lineal de 1 s | El anillo: el final del *trim path* enlazado directo (0 a 1, sin conversor) |
| `icon` | view model `IconSet` | `RiveNextWaveButton` (`nextWave`) | El ícono dentro del anillo |
| `pressed` | boolean | `RiveNextWaveButton` | Se hunde |
| `called` | trigger | `RiveNextWaveButton`, al tocarlo | El anillo y el bono rebotan (0,5 s); el "+N" que flota lo hace el contador de maíz |
| `enabled`, `deny` | boolean, trigger | — | Están, sin uso: el botón solo se muestra si se puede llamar |
| `reduceMotion` | boolean | `RiveBindingState` | Sin rebote |

State machine `Main`: `Press` (`Idle`, `Pressed`, `Release`) y `Call` (`Calm` ← cualquier estado → `Called` con `called`). Al llamar la oleada, la cuenta regresiva desaparece hasta que la oleada termina de salir: `BattleNextWave` deja el botón 0,45 s más, desvaneciéndose y sin recibir toques, para que se vea el rebote.

### `Banner` (Fase 4)

El cartel "Oleada N" que cae al empezar cada oleada, 360 × 150 (copia de `TitleSign` con un grupo `Content` que se anima entero). Con jefe, el tablero se pone rojo y aparece una cinta roja debajo. Widget: `RiveWaveBanner` (`lib/app/rive/rive_banner.dart`), que no recibe toques; en la partida lo pone `BattleWaveBanner` arriba al centro.

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `title` | string | `RiveWaveBanner`, desde los ARB | "Oleada 3" |
| `subtitle` | string | `RiveWaveBanner` | "¡Llega el jefe!" (la cinta) |
| `boss` | boolean | `RiveWaveBanner` | Tablero `BossBoard` rojo y la cinta visibles (opacidad enlazada) |
| `show` | trigger | `RiveWaveBanner`, cada vez que sube `showCount` | Cae desde arriba con rebote y escala (0,5 s), se queda y sube desvaneciéndose: 2,5 s en total; la cinta se menea |
| `reduceMotion` | boolean | `RiveBindingState` | Solo aparece y se desvanece |

State machine `Main`: `Hidden` (todo transparente), `Show` y `ShowCalm`, que vuelven solos a `Hidden`. `showCount` es `BattleHudState.startedWaves`: al montarse (por ejemplo, al volver de la pausa) no se muestra.

### `BuildOption` (Fase 4)

Una tarjeta del menú de construcción, 84 × 108: retrato, nombre y costo con un grano de maíz. En el abanico va al 80 %. Widget: `RiveBuildOption` (`lib/app/rive/rive_build_option.dart`), clave `build-<id>`.

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `name`, `cost` | string | `RiveBuildOption` | El nombre del guardián y su costo |
| `portrait` | view model `Portrait` | `RiveBuildOption` (`portrait/guardian`) | El retrato |
| `selected` | boolean | `RiveBuildOption` | Se levanta 8, crece 8 % y brilla de maíz (0,14 s de mezcla) |
| `affordable` | boolean | `RiveBuildOption` | Sin maíz: velo gris y el costo en rojo `#C62D1F` |
| `locked` | boolean | `RiveBuildOption` | Velo oscuro con candado; el costo se oculta |
| `confirm` | trigger | `RiveBuildOption`, al pasar `confirmed` a `true` | "Pop" (124 %) y desaparece (0,3 s); se queda así |
| `deny` | trigger | `RiveBuildOption`, al tocarla sin maíz o bloqueada | Se sacude ±7° (0,3 s) |
| `reduceMotion` | boolean | `RiveBindingState` | Sin sacudida |

State machine `Main`, cuatro capas: `Select`, `Afford`, `Lock` y `Action` (`Calm`, `Confirm`, `Deny`). `Card` (el todo) se levanta; `Pop` (adentro) hace el "pop" y la sacudida, para que las capas no pisen las mismas propiedades.

### `GuardianInfo` (Fase 4)

La parte de arriba de la ficha de un guardián construido, 224 × 118, sin toques: retrato, "Nombre · Nivel N", a qué ataca con su ícono y dos filas "actual → siguiente". Los textos van en cajas fijas que achican la letra si no entra (`fitFontSize`). Widget: `RiveGuardianInfo` (`lib/app/rive/rive_guardian_info.dart`), dentro de `GuardianCard`.

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `title`, `attacks` | string | `RiveGuardianInfo` | "Hondero · Nivel 2", "Ataca: tierra y aire" |
| `attackIcon` | view model `IconSet` | `RiveGuardianInfo` | `ground`, `air`, `target` (los dos) o `shield` (apoyo) |
| `portrait` | view model `Portrait` | `RiveGuardianInfo` | El retrato |
| `stat1Label`, `stat1Current`, `stat1Next`, `stat1Icon` | string ×3, view model `IconSet` | `RiveGuardianInfo`, desde `GuardianStats` | La estadística principal: daño (`damage`), frena (`pause`, Llama) o brío (`fastForward`, Pututu) |
| `stat2…` | ídem | ídem | El alcance (`target`) |
| `hasNext` | boolean | `RiveGuardianInfo` | Muestra las flechas y los valores siguientes (opacidad enlazada), que laten (116 %, 1 s en bucle) |
| `reduceMotion` | boolean | `RiveBindingState` | Sin latido |

Los tres íconos tienen su propia instancia en la instancia por defecto (`InfoAttack`, `InfoStat1`, `InfoStat2`): con una sola compartida, los tres mostraban el último que se escribió.

### `BranchCard` (Fase 4)

Una rama de la especialización, 156 × 210: encabezado del color del guardián con el nombre, retrato, descripción en varias líneas y costo. Entra girando sola al aparecer. Widget: `RiveBranchCard` (`lib/app/rive/rive_branch_card.dart`), clave `menu-branch-<id>`.

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `name`, `description`, `cost` | string | `RiveBranchCard`, desde los textos del contenido | Lo de la tarjeta |
| `color` | color | `RiveBranchCard` (el del guardián) | El encabezado |
| `portrait` | view model `Portrait` | `RiveBranchCard` | El retrato |
| `selected` | boolean | `RiveBranchCard` | Se levanta y brilla |
| `affordable` | boolean | `RiveBranchCard` | Velo gris y costo en rojo |
| `enter` | trigger | — | Repite la entrada (gira desde −200°, escala elástica, 0,6 s) |
| `choose` | trigger | `RiveBranchCard`, al pasar `chosen` a `true` | Rebota y seis chispas salen disparadas (0,7 s) |
| `reduceMotion` | boolean | `RiveBindingState` | Entra solo desvaneciéndose |

State machine `Main`: `Show` (`Hidden`, `Enter`/`EnterCalm` según `reduceMotion`, `Shown`, `Chosen`), `Select` y `Afford`.

### Cambios de la Fase 4 en el kit

- `Counter`: con `RiveCounter(max:)` muestra "8/10" (las papas) y se dibuja con `Fit.layout` a un ancho medido (`RiveCounter.widthFor`): la pastilla se estira y el número no se corta.
- `SecondaryButton`: capa `Danger` (cara `RedFace` terracota enlazada a `danger`, texto crema y bisel oscuro) para Vender; `RiveButton(danger: true)`.
- `Tooltip`: propiedad `arrow` (boolean; la escribe `RiveTooltip`, por defecto `true`). Sin flecha es la etiqueta de abajo de los menús.
- `TitleSign`: envoltorio `RiveTitleSign` (`lib/app/rive/rive_title_sign.dart`), en la ventana de especialización.

### `Llama` (Fase 5)

La mascota de cuerpo entero, 240 × 270, en vectores: manta turquesa con guarda, collar con borlas. Respira y parpadea siempre; feliz (sonrisa con lengua) o triste (cabeza gacha, orejas caídas, ceño). Widget: `RiveLlama` (`lib/app/rive/rive_llama.dart`), decoración (TalkBack no la lee).

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `mood` | enum `LlamaMood` (`happy`, `sad`) | `RiveLlama` | La pose y la cara (mezcla de 350 ms) |
| `celebrate` | trigger | `RiveLlama`, cada vez que sube `celebrations` | Un saltito y vuelve |
| `reduceMotion` | boolean | `RiveBindingState` | Quieta: sin respirar ni parpadear |

State machine `Main`: capas `Breath` (`Idle` en bucle / `Still`), `Mood` (`Happy` / `Sad`) y `Action` (`Calm` / `Celebrate`, que vuelve sola).

### `SceneSign` (Fase 5)

El cartel de las escenas, 380 × 150: la tabla de `TitleSign` más ancha (300), hojas y dos mazorcas, con el adorno arriba. Cae con un rebote al aparecer (0,67 s). Widget: `RiveSceneSign` (`lib/app/rive/rive_scene_sign.dart`); el panel se apoya en el 70 % de su alto (`RiveSceneSign.panelTop`).

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `title` | string | `RiveSceneSign` | El título (se achica y pasa a dos líneas si no entra) |
| `variant` | enum `SceneVariant` (`pause`, `victory`, `defeat`) | `RiveSceneSign` | Pausa: sol con espiral; victoria: sol que sonríe; derrota: sin sol, madera y hojas más apagadas |
| `reduceMotion` | boolean | `RiveBindingState` | Sin caída ni sol girando |

State machine `Main`: `Layer 1` (`Drop` o `Shown` según `reduceMotion`), `Variant` (`Pause`/`Victory`/`Defeat`) y `Ambient` (`Spin`: los rayos y la espiral dan una vuelta cada 12 s / `Still`).

### `StatPill` (Fase 5)

Una estadística del resultado, 232 × 60: insignia con ícono, etiqueta chica y número grande. El conteo lo hace Flutter (cambia `value` cuadro a cuadro). Widget: `RiveStatPill` (`lib/app/rive/rive_stat_pill.dart`).

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `label`, `value` | string | `RiveStatPill` | "Papas restantes", "14/20" |
| `icon` | view model `IconSet` | `RiveStatPill` | El ícono de la insignia (instancia propia `PillIcon`) |
| `pop` | trigger | `RiveStatPill`, cada vez que sube `pops` | El número crece y la insignia se mece (0,37 s) |
| `reduceMotion` | boolean | `RiveBindingState` | Sin "pop" |

### `UnlockCard` (Fase 5)

Lo que abrió una victoria, 280 × 96 (horizontal, como la referencia): a la izquierda el retrato del guardián o la escena del nivel (una `LevelScene` anidada, como postal inclinada, desde la Fase 6) sobre un destello dorado que gira; a la derecha "Desbloqueado:" y el nombre. No se ve hasta `enter`. Widget: `RiveUnlockCard` (`lib/app/rive/rive_unlock_card.dart`).

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `label`, `name` | string | `RiveUnlockCard` | "Desbloqueado:", "Andenes" |
| `portrait` | view model `Portrait` | `RiveUnlockCard` | El guardián (instancia propia `UnlockPortrait`) |
| `scene` | view model `LevelScene` | `RiveUnlockCard` (`scene/level`) | El nivel (desde la Fase 6; antes era la bandera del `IconSet`) |
| `isLevel` | boolean | `RiveUnlockCard` | Muestra la escena en vez del retrato |
| `enter` | trigger | `RiveUnlockCard`, al pasar `shown` a `true` | Entra con un "pop" (de 30 % a 112 % y 100 %, 0,47 s) |
| `reduceMotion` | boolean | `RiveBindingState` | Entra desvaneciéndose y el destello no gira |

State machine `Main`: `Layer 1` (`Hidden`, `Enter`/`EnterCalm`, que se quedan en su último cuadro), `Glow` (`Spin` en bucle de 8 s / `Still`) y `Kind` (`Guardian`/`Level`).

### `CornRain` (Fase 5)

Catorce granos de maíz que caen girando, 360 × 320, en 2,8 s, y se detiene (la máquina se asienta). Widget: `RiveCornRain` (`lib/app/rive/rive_corn_rain.dart`, `Fit.fitWidth` desde arriba); la victoria pone dos, la segunda espejada, para que los granos no salgan enormes a todo el ancho.

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `rain` | trigger | `RiveCornRain`, cada vez que sube `showers` | Una lluvia |
| `reduceMotion` | boolean | `RiveBindingState` | No llueve |

### `Collca` (Fase 5)

La collca vacía de la derrota, 120 × 120: silo de adobe con techo de paja y la puerta abierta, sin papas; un poco de polvo sube. Widget: `RiveCollca` (`lib/app/rive/rive_collca.dart`), decoración.

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `reduceMotion` | boolean | `RiveBindingState` | El polvo quieto |

### `Valley` (Fase 6)

El paisaje del valle, 960 × 432, en capas: cielo degradado, cuatro nubes, cordillera con nieve, colinas con árboles, lago con isla de totora y un bote, andenes de piedra con la `Collca` llena encima, la chacra (campo, matas de maíz y dos casitas de techo rojo), el camino y delante hojas grandes, quínoa, piedras y dos mazorcas. Fondo del título y del mapa. Widget: `RiveValley` (`lib/app/rive/rive_valley.dart`), cubre a su padre (`Fit.cover`; en el mapa, `Fit.fitWidth` en pantallas más angostas que 2:1).

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `collca` | view model `Collca` | — (instancia `Full`, con `full` = true) | La collca de los andenes; `RiveValley` le pone `reduceMotion` |
| `reduceMotion` | boolean | `RiveBindingState` | Todo quieto |

State machine `Main`: `Layer 1` (`Drift`: las nubes cruzan en 60 s y vuelven a entrar por la izquierda, la cordillera va y viene 6 px y el primer plano 10 px al revés, como parallax / `Still`) y `Glint` (destellos del lago cada 3 s / `Steady`).

### `Logo` (Fase 6)

El logo del título, 520 × 250: cartel de madera con rombo turquesa arriba, hojas y mazorcas a los lados, tres líneas del nombre (crema, la última dorada) y la cinta del lema. Widget: `RiveLogo` (`lib/app/rive/rive_logo.dart`); TalkBack lee el nombre y el lema.

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `line1`, `line2`, `line3` | string | `RiveLogo` (`logoLine1/2/3` de los ARB) | "GUARDIANES" / "DE LA" / "CHACRA" |
| `tagline` | string | `RiveLogo` (`tagline`) | El lema de la cinta |
| `reduceMotion` | boolean | `RiveBindingState` | Aparece armado y sin vaivén |

State machine `Main`: `Layer 1` (`Drop`: el cartel cae, las líneas bajan escalonadas con rebote y la cinta hace "pop", 0,93 s; o `Shown` con menos movimiento) y `Ambient` (`Sway`: hojas ±5° y mazorcas en bucle de 4 s / `Calm`). Las letras caen por línea: el MCP no crea modificadores de texto (letra por letra).

### `Hondero` (Fase 6)

El hondero de cuerpo entero, 200 × 300: la cabeza del retrato (chullo, orejeras, cara) agrandada 1,5×, poncho rojo con franjas turquesa y dorada, un brazo alzado con la honda y sandalias. Widget: `RiveHondero` (`lib/app/rive/rive_mascots.dart`), decoración.

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `reduceMotion` | boolean | `RiveBindingState` | Quieto y con la honda en reposo |

State machine `Main`: `Layer 1` (`Idle`: la cabeza respira y se ladea 2,5°, parpadea cada 3 s / `Still`) y `Sling` (`Spin`: la honda da una vuelta cada 0,8 s / `Hold`).

### `GorgojoPeek` (Fase 6)

Un gorgojo gruñón que se asoma entre tres hojas, 140 × 110: cada 8 s sube, mira a un lado y al otro y se esconde. Widget: `RiveGorgojoPeek` (`lib/app/rive/rive_mascots.dart`, `mirrored` para el de la derecha), decoración.

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `reduceMotion` | boolean | `RiveBindingState` | No se asoma |

### `LevelNode` (Fase 6)

Un nivel en el mapa, 160 × 150: pedestal de piedra, círculo verde con borde crema y el número (Fredoka con contorno), cinta crema con el nombre y una barra oscura con 3 estrellas. Cerrado: el disco gris (`DiscLocked`) y un candado dorado; sugerido: un anillo dorado con resplandor. Widget: `RiveLevelNode` (`lib/app/rive/rive_level_node.dart`); se ancla en el mapa por el centro del círculo (`LevelNodeRive.circleCenter`, 0,5 × 0,32).

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `number`, `name` | string | `RiveLevelNode` | El número del círculo y el nombre de la cinta (achica la letra si no entra) |
| `stars` | number | `RiveLevelNode` | Las estrellas llenas (0 a 3) |
| `state` | enum `LevelNodeState` (`locked`, `available`, `chosen`) | `RiveLevelNode` | Cerrado, abierto o sugerido |
| `shake` | trigger | `RiveLevelNode` (cuando sube `shakes`) | El círculo se sacude y el candado se bambolea |
| `unlock` | trigger | `RiveLevelNode` (cuando sube `unlocks`) | El candado salta y se desvanece y el círculo hace "pop" |
| `reduceMotion` | boolean | `RiveBindingState` | Sin flotar, sin pulso, sin sacudida ni "pop" |

Lo que se ve u oculta según el estado y las estrellas no usa poses: la opacidad va enlazada al view model con conversores (`IsIcon00` e `IsIcon02` del `IconSet` para "es el primero / el tercero del enum", y los nuevos `EnumNotFirst` y `AtLeast1/2/3`). State machine `Main`: `Float` (`Bob`: el círculo sube y baja 4,5 px en 2 s si no está cerrado / `Still`), `Ring` (`Pulse`: el anillo y el resplandor laten en 1,2 s si es el sugerido / `Calm`) y `Action` (`Rest` → `Shake` 0,45 s o `Unlock` 0,9 s → `Rest`).

### `LevelScene` (Fase 6)

La ilustración de un nivel, 240 × 150: una copia del paisaje del `Valley` (sin animaciones) dentro del grupo `Camera`, escalada al 60 % y encuadrada en la chacra, los andenes o la orilla del lago, con un marco crema. Widget: `RiveLevelScene` (`lib/app/rive/rive_level_scene.dart`, con las esquinas recortadas en Flutter); va en la barra del valle y, en la parte C, en la vista previa y en la tarjeta de desbloqueo.

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `level` | enum `LevelId` (`chacra`, `andenes`, `lago`) | `RiveLevelScene` (de `LevelSceneRive.levels`) | Qué parte del valle se ve |
| `collca` | view model `Collca` | — (instancia `Full`) | La collca de los andenes; `RiveLevelScene` le pone `reduceMotion` |

State machine `Main`: `Framing`, un estado por nivel (`Chacra`, `Andenes`, `Lago`) que mueve `Camera`. El artboard recorta lo que sale de su marco (`clip`): anidado en la `UnlockCard` no se ve el resto del valle. Un nivel que el dibujo no conoce usa el respaldo de Flutter.

### Los retratos de las plagas y `PestPortrait` (Fase 6)

Un artboard por plaga, 120 × 120, en el estilo de los retratos de los guardianes (plano, contorno `#4A1302` de 2,4, fondo transparente, cejas de pocos amigos): `PestGorgojo` (el gorgojo de trompa larga), `PestReyGorgojo` (el mismo con capa ciruela y corona con gemas), `PestPolilla`, `PestLangosta`, `PestEscarabajo` (caparazón acorazado con cuerno), `PestGranizo` (bola de hielo con púas y dientes apretados), `PestGranizoChico` (más chico y sonriente) y `PestEspirituHelada` (fantasma celeste con copo de nieve en la frente).

`PestPortrait` los anida a los ocho junto con `PortraitUnknown` (la silueta con "?" de los guardianes, el respaldo) y muestra uno: la opacidad de cada componente va enlazada a `pest` con `IsIcon00`…`IsIcon08`. Va anidado en `PestCard`; en la Fase 7, también en el Bestiario.

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `pest` | enum `PestId` | `RivePestCard` (`portrait/pest`) | `unknown`, `gorgojo`, `polilla`, `langosta`, `granizo`, `granizo_chico`, `escarabajo`, `espiritu_helada` o `rey_gorgojo` |

Como con los guardianes, el primer valor es el respaldo y `PestPortraitRive.valueFor` cambia un id desconocido por `unknown`. Para sumar una plaga: dibujar su artboard, anidarlo en `PestPortrait`, agregar el valor al final del enum, enlazar su opacidad con `IsIconNN` y sumar el id a `PestPortraitRive.ids` (el test de contrato compara las dos listas).

### `PestCard` (Fase 6)

La tarjeta de una plaga en la preparación, 132 × 180: marco crema (ciruela, el jefe), una ventana del color de la plaga con el `PestPortrait`, el nombre debajo (en dos líneas si no entra; achica la letra si hace falta), la insignia turquesa "Nueva" arriba a la derecha y, el jefe, la cinta "Jefe final" sobre el borde de la ventana y un resplandor dorado detrás de la corona. Widget: `RivePestCard` (`lib/app/rive/rive_pest_card.dart`).

| Propiedad | Tipo | La escribe | Qué hace |
|---|---|---|---|
| `name` | string | `RivePestCard` | El nombre de la plaga |
| `isNew`, `newLabel` | boolean, string | `RivePestCard` | La insignia "Nueva" (no se vio todavía) |
| `boss`, `bossLabel` | boolean, string | `RivePestCard` | El marco ciruela, la cinta "Jefe final" y el resplandor |
| `color` | color | `RivePestCard` (`windowColor`: el color de la plaga mezclado con 60 % de blanco) | El fondo de la ventana |
| `portrait` | view model `PestPortrait` | `RivePestCard` | El retrato |
| `enter` | trigger | `RivePestCard`, al pasar `shown` a `true` | Sube 18 px, crece de 92 % a 100 % y aparece (0,4 s) |
| `reduceMotion` | boolean | `RiveBindingState` | Aparece sin moverse y el resplandor no late |

Lo que depende de `boss` e `isNew` se muestra enlazando la opacidad con `BoolToNumber`. State machine `Main`: `Enter` (`Hidden` → `Enter` o `EnterCalm`, que se quedan en su último cuadro) y `Glow` (`Shine`: el resplandor late en 1,6 s si es el jefe / `Calm`).

### Cambios de la Fase 6 en piezas anteriores

- `Llama`: propiedad `chewing` (boolean; `RiveLlama(chewing:)`) y capa `Chew` (tres mordiscos y una pausa, bucle de 2 s; no con menos movimiento). La masca en el título.
- `Collca`: propiedad `full` (boolean) y capa `Fill`: con papas en la puerta y sin polvo. La de la derrota sigue vacía.

## El kit en Flutter (Fase 3)

- `RiveBinding` (`lib/app/rive/rive_binding.dart`) crea el controlador de un artboard con la state machine `Main` y ata su view model por defecto (`DataBind.auto()`: cada widget tiene su propia instancia, también la del ícono anidado). Pide las propiedades por nombre y lanza `RiveContractException` si falta alguna.
- `RiveBindingState` es la base de cada envoltorio: crea el binding si el archivo está cargado, le pone los valores iniciales (`bind`), llena `reduceMotion` desde `MediaQuery.disableAnimations` y lo libera al final. Sin archivo, o si falta una propiedad, el widget dibuja su respaldo del tema.
- Los toques los recibe Flutter: cada envoltorio tiene su `GestureDetector`, su `Semantics` (botón, interruptor, opción elegida) y la Key que le pase la pantalla. Rive dibuja con `RiveHitTestBehavior.none`.
- `RiveNumberTween` (en el mismo archivo) lleva un número del view model a su valor nuevo cuadro a cuadro. Hace falta porque **Rive no anima los layouts cuando el valor llega por data binding**: en el Redmi la pastilla del selector y el relleno de la barra saltaban. Con menos movimiento, el valor cambia de golpe.
- `UiFeedback` (`lib/app/ui_feedback.dart`) toca `Sfx.uiTap` o `Sfx.uiDeny` (sonidos sintetizados por `tool/generate_placeholder_audio.py`) y vibra `Haptic.tap` (`selectionClick`) o `Haptic.deny` (`lightImpact`), respetando los interruptores de Efectos y Vibración. Desde la Fase 5, `star()`: `Sfx.star` y `Haptic.star` (`mediumImpact`) para cada estrella de la victoria.
- Dónde se usa ya: los botones del título (`menu-play`, `menu-bestiary`, `menu-settings`), de la preparación (`preview-start`, `preview-rewarded`) y de los overlays de la partida (`pause-resume`, `victory-next`, `battle-retry`, `battle-exit`, `battle-revive`). El HUD y los menús de la partida llegaron en la Fase 4 y las escenas de pausa, victoria y derrota en la 5 (abajo); los demás esperan su fase (menús en la 6, bestiario y ajustes en la 7).

## La batalla en Flutter (Fase 4)

- **HUD** (`lib/features/battle/presentation/hud/battle_hud.dart`): `BattleHud` arriba (maíz, papas "N/máx" con pulso rojo al 30 % o menos, barra de oleadas roja si la oleada trae jefe; velocidad, 🐞 solo en debug y pausa), `BattleNextWave` abajo a la derecha (se oculta mientras la ficha de un guardián ocupa ese rincón) y `BattleWaveBanner` arriba al centro. Todo sale de `BattleHudState`, que ahora también trae `maxPotatoes`, `startedWaves`, `boss` y `nextWaveTotalSeconds` (de `Simulation.startingPotatoes`, `waveHasBoss` y `nextWavePrepTicks`).
- **Construcción** (`BuildMenu` en `menus/battle_menus.dart`): todos los guardianes en abanico alrededor del espacio, saliendo uno tras otro (Flutter mueve las tarjetas; Rive dibuja los estados). Los bloqueados se ven con candado y su regla ("Se abre al ganar Andenes"); tocarlos o tocar uno sin maíz los sacude y la etiqueta de abajo (`MenuLabel`, un `RiveTooltip` sin flecha) dice por qué. Primer toque: marca y muestra el alcance; segundo: "pop" y el menú se cierra a los 0,28 s.
- **Ficha** (`GuardianCard`): un `RivePanel` del lado contrario al guardián con `RiveGuardianInfo` y los botones Mejorar · costo (o Especializar en el último nivel), Objetivo: … (un toque) y Vender +N (terracota), y cerrar. Mejorar y Vender piden dos toques; la etiqueta de abajo lo recuerda. `GuardianStats` saca las filas de los datos del guardián.
- **Especialización** (`SpecializationWindow`): un velo con el cartel, el subtítulo, las dos `RiveBranchCard`, cerrar y Elegir. La simulación queda en pausa (`clock.paused`) pero Flame sigue dibujando, así se ve el alcance de la rama marcada. Elegir (o un segundo toque en la tarjeta) la confirma: estalla y la ventana se cierra a los 0,75 s.
- **Alcance en el mapa** (`RangeComponent`): relleno turquesa suave y borde punteado turquesa sobre un contorno oscuro.
- Claves para los tests: las de siempre (`hud-next-wave`, `hud-speed`, `hud-pause`, `hud-dev`, `build-<id>`, `menu-upgrade`, `menu-branch-<id>`, `menu-sell`, `menu-targeting`) y las nuevas `hud-corn`, `hud-potatoes`, `hud-wave`, `menu-specialize`, `menu-close`, `menu-branch-confirm`, `menu-branch-close` y `menu-label`.
- `test/app/rive/rive_battle_ui_test.dart` dibuja todas estas piezas con el archivo real y falla si alguna cae a su respaldo; con `--dart-define=BATTLE_UI_PNG=build/battle_ui.png` guarda la imagen.

## Las escenas en Flutter (Fase 5)

`lib/features/battle/presentation/overlays/battle_overlays.dart`. Las tres comparten el armado: un velo que se oscurece en 250 ms, un `RivePanel` que cae y un `RiveSceneSign` apoyado en su borde de arriba (`_Scene`). Todo va dentro de un `FittedBox(scaleDown)`: si no entra (teléfono bajo, letra grande) se achica entero en vez de cortarse. Los botones (`_DelayedButtons`) aparecen a los 280 ms, al terminar de caer el panel; antes no reciben toques.

- **Pausa** (`PauseOverlay`): cartel "Pausa" con el sol que gira, "La chacra puede esperar", Continuar ancho (de maíz) y debajo Reintentar y Salir del nivel (terracota, `danger`). Sin X, como se decidió.
- **Victoria** (`VictoryOverlay`): la llama parada a la izquierda tapando el borde del panel, estrellas, `RiveStatPill` de papas ("14/20") y maíz, hasta dos `RiveUnlockCard` (`UnlockedItem.level` o `.guardian`) y los botones. La coreografía la marca `VictoryTimeline` (en ms): estrellas a los 520, 900 y 1280 (cada una con `UiFeedback.star()`), el conteo 460 ms después de la última y durante 700 ms (al terminar, "pop"), los desbloqueos 200 ms después, cada 260 ms, y al final la lluvia y el salto de la llama. Un `AnimationController` recorre la línea y el estado solo cambia cuando cambia algo visible. Un toque fuera de los botones (o menos movimiento) salta al final sin más sonidos.
- **Derrota** (`DefeatOverlay`): entra temblando (`_Shake`, 600 ms; quieto con menos movimiento); la llama triste junto a la `RiveCollca`, la pastilla "0/20", "Prueba otra combinación de guardianes.", Reintentar (principal) y Volver al valle; "Ver anuncio…" (`battle-revive`) apoyado en el borde de abajo, solo si hay anuncio cargado y no se revivió.
- Datos: `BattleScreen` pasa las estrellas, `Simulation.potatoes` y `startingPotatoes`, `BattleStats.cornHarvested`, `Unlocked` (niveles con su nombre y color, guardianes con su id para el retrato) y `AdsStatus`.
- Claves: `pause-resume`, `victory-next`, `battle-retry`, `battle-exit`, `battle-revive` y `victory-unlocked` (la fila de tarjetas).
- `test/app/rive/rive_scenes_test.dart` dibuja las tres en un teléfono apaisado con el archivo real y las letras del juego (sin ellas los botones miden de más) y falla si algo cae a su respaldo; con `--dart-define=SCENES_PNG=build/scene` guarda `build/scene_pausa.png`, etc. `test/features/battle/presentation/overlays/battle_overlays_test.dart` prueba la coreografía con y sin Rive.

## El título en Flutter (Fase 6, parte A)

`lib/features/menu/presentation/title_screen.dart`: `RiveValley` de fondo; el hondero a la izquierda y la llama masticando a la derecha (alto = mín(68 % del alto, 30 % del ancho), para que en 4:3 no toquen el logo); dos gorgojos asomándose junto a sus pies; y al centro el logo (ancho = mín(42 % del ancho, 1,1 × el alto)), Jugar del ancho de Bestiario y Ajustes juntos, que "respira" (un 4 % cada 1,4 s), y los otros dos debajo. Todo el centro va en un `FittedBox(scaleDown)`. Sin el archivo de Rive, el título de siempre (nombre y lema en Flutter) sobre un degradado de cielo y chacra, sin mascotas ni respiración, así los tests pueden esperar a que se asiente. Claves: `menu-play`, `menu-bestiary`, `menu-settings`.

## El valle en Flutter (Fase 6, parte B)

`lib/features/level_select/presentation/level_select_screen.dart`, sin AppBar:

- De fondo, el `RiveValley`. `ValleyFrame` (`valley_layout.dart`) dice cómo se escala: cubriendo en pantallas de 2:1 o más anchas y, en las más angostas, ajustado al ancho y apoyado abajo. Con la misma transformación se ubican los nodos sobre puntos del dibujo (`valleyAnchors`: la chacra junto a las casitas, los andenes a la derecha de la collca y la orilla sobre la totora). Un nivel que el dibujo no conoce usa el reparto de `valleyNodePositions`.
- Los nodos (`RiveLevelNode`, 15,5 % del ancho, entre 112 y 150 dp) se tocan en Flutter: abierto → la vista previa; cerrado → se sacude y aparece encima el globo (`RiveTooltip`) con la regla durante 3 s, o hasta tocar el mapa (antes era un snackbar). TalkBack lee "Nombre: N de 3 estrellas" o "Nombre: bloqueado", y el globo al aparecer. El sugerido (`Progression.suggested`: el primero abierto sin estrellas; si no hay, el que tiene menos; con todo en 3, el último abierto) lleva el anillo.
- El camino de piedritas lo dibuja Flutter (`_TrailPainter`), solo hasta los niveles abiertos. Al ganar, la batalla anota los niveles nuevos en `valleyRevealProvider`; cuando el valle vuelve a estar a la vista, el camino hasta cada uno aparece piedra por piedra en 1,2 s, el candado salta (`unlock`) y suena la estrella. Vive en memoria: si el juego se cierra antes, el camino aparece hecho. Con "Quitar animaciones", también.
- Arriba: Volver (redondo, `RiveIcon.back`), el `TitleSign` "El valle" y el contador de estrellas (`RiveCounter` con la estrella, "N/9"). Abajo, en un `RivePanel`: la `RiveLevelScene` del sugerido, su nombre y sus estrellas (`RiveStar`) y Jugar, que lleva a su vista previa; con letra grande se achica (hasta el 27 % del alto) para no tapar los niveles.
- Claves: `level-<id>`, `valley-back`, `valley-play`, `valley-stars`.

## La preparación en Flutter (Fase 6, parte C)

`lib/features/level_select/presentation/level_preview_screen.dart`, sin AppBar, sobre el `RiveValley` (con el mismo `ValleyFrame` del mapa):

- Arriba, en una fila que se achica entera con letra grande: las oleadas (`RiveStatPill` con la bandera), el `TitleSign` con el nombre del nivel, el maíz inicial y las papas (`RiveStatPill` al 60 %). TalkBack lee "Oleadas: 10", etc.
- A la izquierda, la `RiveLevelScene` del nivel (27 % del ancho, hasta 240 dp). A la derecha, en un `RivePanel`, "Plagas que vienen" y la fila de `RivePestCard` en el orden en que llegan, en un `ListView` horizontal: el ancho de cada tarjeta deja ver cinco enteras y un poco de la sexta, sin pasarse del alto. Entran una tras otra, cada 90 ms (con "Quitar animaciones", todas a la vez).
- Tocar una tarjeta muestra encima un globo (`RiveTooltip`) con la descripción de la plaga del Bestiario; se va a los 4 s, al tocar fuera o al deslizar la fila. TalkBack lee "Nombre, Nueva, Jefe final" y el globo al aparecer.
- Abajo: Volver (`preview-back`), "Ver anuncio: +50 de maíz" solo si hay uno cargado (`preview-rewarded`) y Comenzar (`preview-start`). Claves de las tarjetas: `preview-pest-<id>`; de las pastillas, `preview-waves`, `preview-corn` y `preview-potatoes`.
- El toque que cierra el globo (en el valle y aquí) lleva `excludeFromSemantics`: si no, TalkBack juntaba toda la pantalla en un nodo con el título.

## Paleta

La misma de CLAUDE.md ("Decisiones (UI)") y de `AppTheme` en Flutter. Combinaciones de texto (WCAG):

| Texto sobre | Contraste | Uso |
|---|---|---|
| `#4A1302` sobre crema `#FEF3D7` | 13,7:1 | Texto normal |
| `#4A1302` sobre maíz `#FDB119` | 8,3:1 | Botón principal |
| Crema sobre madera `#9E430B` | 5,8:1 | Carteles, barra de arriba |
| Crema sobre terracota `#B5452A` | 4,9:1 | Vender |
| Verde `#117D16` sobre crema | 4,8:1 | Números que suben |
| Verde `#0E6B12` sobre crema HUD `#FDEAC5` | 5,7:1 | Bono del HUD |
| Crema sobre ciruela `#8B2055` | 7,8:1 | Jefe |
| Crema sobre turquesa `#0B889F` | 3,8:1 | Solo texto grande o íconos |
| Crema sobre verde `#36901D` | 3,7:1 | Solo íconos (el visto del interruptor) |

La estrella amarilla `#FECE18` sobre crema da 1,35:1: siempre lleva su contorno oscuro (10:1).

## Fuentes

| Fuente | Para qué | En Rive | En Flutter |
|---|---|---|---|
| Lilita One | Títulos y carteles | Completa (28 KB): no se recorta porque su licencia reserva el nombre "Lilita" para versiones modificadas | `AppTheme.titleFont`: `displayMedium`, `headlineSmall` y la barra de arriba |
| Fredoka (variable, 300–700) | Todo lo demás | Recortada a los caracteres del español y el inglés | `AppTheme.bodyFont`, la fuente por defecto; `FontWeight` elige el peso sin `fontVariations` |

Las dos tienen licencia SIL OFL 1.1 y están en `assets/fonts/` con su `OFL.txt` (que `main.dart` suma a la pantalla de licencias). En el editor de Rive no se pueden subir fuentes por el MCP (no permite `.ttf`): se agregaron desde el selector de fuentes del editor (catálogo de Google Fonts) y después se asignaron a cada texto con `fontassetid`.

El recorte de Fredoka se escribe en su asset ("caracteres incluidos" en modo personalizado) como **rangos Unicode**, no como los caracteres sueltos (ver "El error de la fuente" más abajo):

```
U+0020-007E,U+00A1,U+00BF,U+00C1,U+00C9,U+00CD,U+00D1,U+00D3,U+00DA,U+00DC,U+00E1,U+00E9,U+00ED,U+00F1,U+00F3,U+00FA,U+00FC,U+00B7,U+00D7,U+2013-2014,U+2018-2019,U+201C-201D,U+2026,U+2192,U+2265
```

Es ASCII más `¡ ¿ Á É Í Ñ Ó Ú Ü á é í ñ ó ú ü · × – — ‘ ’ “ ” … → ≥`. Si un texto nuevo usa otro carácter, hay que sumarlo a la lista. Con Inter (Fase 1) el `.riv` pesaba 199 KB; con Lilita One completa y Fredoka recortada, 144 KB.

## Tests y librerías nativas

Rive usa código nativo (`rive_native`). Para compilar la app no hay que hacer nada: el build lo descarga. Para `flutter test` (los tests de `test/app/rive/` y el del catálogo de desarrollo cargan el archivo real) hay que bajarlo una vez por PC:

```powershell
dart run tool/setup_rive_native.dart
```

En Windows, los tests cargan la DLL de depuración de Rive, que pide el runtime de depuración de C++ (`MSVCP140D.dll`, `ucrtbased.dll`): solo viene con Visual Studio y sin él falla con "error code 126". El script copia encima la DLL de lanzamiento, que usa el runtime normal que ya trae Windows. El CI (Linux) corre el mismo script antes de los tests.

## Mediciones de la Fase 1

19 de octubre de 2026, Redmi Note 14 Pro (pantalla de 120 Hz), APK de profile, Chacra del Valle sin guardianes, collca invencible. "Estrés" = la prueba de 150 plagas del panel de desarrollo, a x2. Los cuadros se midieron con SurfaceFlinger (`dumpsys SurfaceFlinger --latency` sobre la capa del juego): cinco muestras de los últimos ~128 cuadros presentados. A 120 Hz, un cuadro a tiempo dura 8,3 ms; uno de más de 16,7 ms ya baja de 60 FPS.

Las pruebas con varios contadores usan el panel de desarrollo ("Prueba de Rive", `lib/dev/rive_bench.dart`): contadores que cambian cada 250 ms (más seguido que su animación de 0,4 s, así que no paran de animarse).

| Situación | Sin Rive (respaldo) | Renderer de Flutter | Renderer de Rive | Renderer de Rive + `RivePanel` |
|---|---|---|---|---|
| Partida normal, contador del HUD | 118 FPS | 119 FPS | 118 FPS | — |
| Estrés, contador del HUD | 118 FPS | 118 FPS | 117 FPS | — |
| Estrés + 6 contadores, 2 animándose (como el HUD de la Fase 4) | — | **114 FPS** (4 % de cuadros > 16,7 ms) | 59 FPS (80 %) | 75 FPS (46 %) |
| Estrés + 12 contadores animándose (peor caso) | — | 80–81 FPS (35 %) | 29–30 FPS (100 %) | 62 FPS (75 %) |

`RivePanel` no funciona con el renderer de Flutter: `RiveWidget` muestra un error en lugar del dibujo. `RiveCounter` ya no pide la textura compartida con ese renderer.

### Qué decidimos

- **Renderer: el de Flutter** (`Factory.flutter`, el valor por defecto de `RiveUi.renderer`). Dentro del juego, con Flame dibujando al mismo tiempo, cada widget con el renderer de Rive tiene su propia textura y eso cuesta mucho; el de Flutter dibuja en el mismo lienzo que el resto de la app. Lo que se pierde: el *vector feathering* (bordes difuminados) del editor solo existe con el renderer de Rive, así que los brillos y sombras suaves se hacen con degradados y trazos. `--dart-define=RIVE_RENDERER=rive` sigue disponible para volver a comparar.
- **Cuántos widgets de Rive por pantalla**: en batalla, hasta unos 6 controles con pocas animaciones a la vez (el HUD) cuesta unos 4 FPS de 118. Doce animándose sin parar ya baja a 80: en batalla no se animan muchas cosas a la vez ni se dejan bucles de reposo corriendo. En los menús y en los overlays (la partida en pausa o terminada) hay más margen.
- **Un artboard por control o por panel**: un artboard por control tocable (lo que acordamos en el Prompt 0) aguanta el rendimiento con el renderer de Flutter. Los paneles y escenas sin toques (victoria, título) van en un solo artboard grande, que además permite coordinar sus animaciones.
- **Las máquinas que se asientan no cuestan**: un contador quieto no hace repintar nada (fila "Partida normal"). Por eso los estados de reposo de cada state machine terminan en una animación de un solo disparo, no en un bucle, salvo que el bucle sea parte del diseño (y entonces se apaga con `reduceMotion` y en batalla).

### Peso

`rive` agrega `librive_native.so`: en arm64 son 7,7 MB instalados y unos 2,8 MB comprimidos, que es más o menos lo que se descarga desde Google Play con un App Bundle (cada teléfono baja solo su arquitectura). En el APK universal hay tres copias (arm64, armeabi-v7a y x86_64: 22,5 MB sin comprimir). El `.riv` pesaba 199 KB en la Fase 1 (casi todo era la fuente Inter); con Lilita One y Fredoka recortada y el kit de la Fase 3 completo, pesaba 164 KB; con los retratos y las piezas de batalla de la Fase 4, 189 KB. El código Dart de Rive, unos 70 KB.

### El error de la fuente

La primera exportación recortó la fuente escribiendo los caracteres tal cual en "caracteres incluidos": el editor no lo entendió, el `.riv` quedó en 16 KB y **el número no se dibujaba** (la pastilla salía vacía en el teléfono). El campo espera rangos Unicode (`U+0020-007E,U+00A1,…`). `rive_counter_test.dart` ahora cuenta los píxeles del texto para que no vuelva a pasar sin que nadie lo note.

## Mediciones de la Fase 4

20 de octubre de 2026, el mismo Redmi y el mismo método (APK de profile, SurfaceFlinger, cinco muestras), Chacra del Valle sin guardianes, ahora con el HUD completo de Rive: contadores de maíz y de papas, barra de oleadas, velocidad, pausa, siguiente oleada (con el anillo animándose) y el cartel de cada oleada.

| Situación | Fase 1 | Fase 4 |
|---|---|---|
| Partida normal a x1 | 119 FPS (un contador de Rive) | **116 FPS** (2 % de cuadros > 16,7 ms) |
| Estrés a x2 | 118 FPS (un contador) · 114 FPS (6 contadores, 2 animándose) | **106 FPS** (7 % > 16,7 ms; p50 8,4 ms, p95 16,8 ms) |

La única animación que no para es la de las flechitas del botón de velocidad a x2 (bucle de 0,8 s, como pide el diseño; con "menos movimiento" quedan quietas). Si en un teléfono más lento hiciera falta, se puede dejar que avancen unas vueltas al cambiar a x2 y después se queden quietas (`FastLoop` → `FastStill`). Los menús, la ficha y la especialización no corren durante el estrés.

## Mediciones de la Fase 5

20 de octubre de 2026, el mismo Redmi y SurfaceFlinger (cinco muestras), esta vez con el APK de **debug** (en profile serían iguales o mejores), Chacra del Valle.

| Escena | FPS | Cuadros > 16,7 ms |
|---|---|---|
| Pausa (el sol gira, la partida quieta) | **119** | 0 % |
| Victoria ya terminada (la llama respira) | **116** | 2 % |
| Derrota tras la prueba de estrés (llama, polvo y 150 plagas detrás) | 107 | 11 % (p95 16,8 ms) |

La derrota se midió con las 150 plagas del estrés todavía dibujadas detrás del velo; la victoria, con la misma llama y sin plagas, da 116, así que la diferencia es de Flame y no de las escenas. La coreografía de la victoria dura unos 3 s y la lluvia se detiene sola (sus máquinas se asientan).

## Mediciones de la Fase 6 (parte A)

20 de octubre de 2026, el mismo Redmi y SurfaceFlinger (cinco muestras), APK de profile, el título ya armado (más de 15 s después de abrir el juego), con todo animándose: nubes y parallax del valle, hojas del logo, honda, llama masticando, gorgojos y Jugar respirando.

| Medición | Resultado |
|---|---|
| Cuadros presentados | **90 FPS** (30 % > 16,7 ms; p50 8,4 ms, p95 16,9 ms, máx. 25–34 ms) |
| Overlay de rendimiento de Flutter | raster 10,7 ms por cuadro de media (máx. 13,6); UI 5,4 ms (máx. 8,8) |
| APK de debug, justo al abrir | 53 FPS (en debug el Dart es mucho más lento; sirve solo para comparar) |

El límite es el hilo de raster: el valle cubre toda la pantalla y se mueve sin parar, e Impeller vuelve a rasterizar la escena entera en cada cuadro (no tiene la caché de raster de Skia). Pasa los 8,3 ms de un cuadro a 120 Hz, pero ninguno llega a 16,7 ms de media, así que en una pantalla de 60 Hz el título no perdería cuadros. Envolver cada widget de Rive en un `RepaintBoundary` (el render box de Rive no lo es) no cambió nada (89–90 FPS con y sin), porque solo ahorra trabajo del hilo de UI: no lo dejamos. Si el mapa del valle (parte B) necesitara más margen, la salida sería dibujar las capas quietas del paisaje una vez a imagen y mover solo las nubes.

## Mediciones de la Fase 6 (parte B)

21 de octubre de 2026, el mismo Redmi, APK de profile y SurfaceFlinger, el valle asentado con los tres niveles abiertos (las nubes cruzan, los tres nodos flotan y el sugerido late): **86–90 FPS** (28–34 % de cuadros > 16,7 ms; p50 8,4 ms, p95 16,9 ms). Lo mismo que el título: el límite sigue siendo el raster del valle a pantalla completa; los nodos, el camino y la barra no suman casi nada.

## Mediciones de la Fase 6 (parte C)

21 de octubre de 2026, el mismo Redmi, APK de profile y SurfaceFlinger, la preparación de Andenes con las siete tarjetas ya entradas (el valle de fondo sigue animándose y el brillo del jefe late): **77 FPS** (50 % de cuadros > 16,7 ms; p50 16,7 ms, p95 16,9 ms, máx. 25 ms). Más que en el valle porque hay más Rive en pantalla (siete tarjetas con su retrato anidado y una segunda copia del valle en la escena del nivel), pero ningún cuadro baja de 40 FPS y casi todos quedan en 60. Si hiciera falta margen: las tarjetas ya asentadas no repintan; lo caro sigue siendo el valle de fondo.
